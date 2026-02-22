import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/deck/deck_bloc.dart';
import '../../blocs/deck/deck_event.dart';
import '../../blocs/deck/deck_state.dart';
import '../../blocs/flashcard/flashcard_bloc.dart';
import '../../blocs/flashcard/flashcard_event.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../services/ai_deck_service.dart';

// ---------------------------------------------------------------------------
// API key is loaded from --dart-define=GEMINI_API_KEY=your_key at run time.
// Get a free key at: https://aistudio.google.com/app/apikey
//
// When ready to release publicly, see:
//   lib/services/firebase_function_generator_service.dart
// for the one-line swap to use a Firebase Cloud Function instead.
// ---------------------------------------------------------------------------
const _kGeminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: '',
);

class AiGenerateScreen extends StatefulWidget {
  const AiGenerateScreen({super.key});

  @override
  State<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends State<AiGenerateScreen> {
  // Typed as the abstract interface — swap to FirebaseFunctionGeneratorService
  // when upgrading to Blaze plan. See firebase_function_generator_service.dart.
  final CardGeneratorService _service = GeminiDirectService(_kGeminiApiKey);
  final _topicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _fileName;
  String? _fileText;
  int _cardCount = 15; // user-adjustable (5–30)
  bool _capitalise = true; // auto-capitalise first letter of each card side

  // "Add to existing deck" mode
  Deck? _targetDeck; // null = create new deck

  // Once generated, cards are shown here for preview/editing
  List<_EditableCard> _suggestions = [];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  /// Capitalises the first letter of [s] when [_capitalise] is true.
  String _fmt(String s) {
    if (!_capitalise || s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // ── File picker ──────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    String text;
    if (file.bytes != null) {
      text = String.fromCharCodes(file.bytes!);
    } else if (file.path != null) {
      text = await File(file.path!).readAsString();
    } else {
      return;
    }

    setState(() {
      _fileName = file.name;
      _fileText = text;
      _topicController.clear();
    });
  }

  // ── Generation ───────────────────────────────────────────────────────────

  Future<void> _generate() async {
    if (_kGeminiApiKey.isEmpty) {
      _snack(
        'No Gemini API key configured.\n'
        'Run: flutter run --dart-define=GEMINI_API_KEY=your_key',
        isError: true,
      );
      return;
    }
    if (_fileText == null && !_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _suggestions = [];
    });
    try {
      final cards = _fileText != null
          ? await _service.generateFromText(_fileText!)
          : await _service.generateFromTopic(
              _topicController.text.trim(),
              count: _cardCount,
            );

      setState(() {
        _suggestions = cards
            .map((c) => _EditableCard(front: _fmt(c.front), back: _fmt(c.back)))
            .toList();
      });
    } catch (e) {
      _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Fetches another batch and appends non-duplicate cards to the preview.
  Future<void> _loadMore() async {
    if (_kGeminiApiKey.isEmpty || _fileText != null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final existing = _suggestions.map((c) => c.front).toList();
      final cards = await _service.generateFromTopic(
        _topicController.text.trim(),
        count: _cardCount,
        exclude: existing,
      );

      int added = 0;
      setState(() {
        for (final c in cards) {
          final alreadyShown = _suggestions.any(
            (s) => _normalise(s.front) == _normalise(c.front),
          );
          if (!alreadyShown) {
            _suggestions.add(
              _EditableCard(front: _fmt(c.front), back: _fmt(c.back)),
            );
            added++;
          }
        }
      });
      if (added == 0) {
        _snack('No new cards found — try rephrasing your topic.');
      } else {
        _snack('Added $added more cards to preview.');
      }
    } catch (e) {
      _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Duplicate detection ───────────────────────────────────────────────────

  /// Returns true if [candidate] is too similar to any existing card front.
  /// Uses case-insensitive exact match + simple normalisation.
  bool _isDuplicate(String candidate, List<Flashcard> existing) {
    final norm = _normalise(candidate);
    return existing.any((c) => _normalise(c.front) == norm);
  }

  String _normalise(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _saveDeck() async {
    final cards = _suggestions.where((c) => !c.removed).toList();
    if (cards.isEmpty) {
      _snack('No cards to save.', isError: true);
      return;
    }

    final now = DateTime.now();

    if (_targetDeck != null) {
      // ── Add to existing deck ─────────────────────────────────────────────
      final deck = _targetDeck!;

      // Load existing cards to deduplicate
      final existing = await context
          .read<FlashcardBloc>()
          .repository
          .getFlashcards(deck.id);

      final newCards = <Flashcard>[];
      int skipped = 0;
      for (final card in cards) {
        if (_isDuplicate(card.front, existing)) {
          skipped++;
        } else {
          newCards.add(
            Flashcard(
              id: const Uuid().v4(),
              deckId: deck.id,
              front: card.front,
              back: card.back,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }

      if (newCards.isEmpty) {
        _snack(
          'All ${cards.length} cards already exist in "${deck.name}". Nothing added.',
        );
        return;
      }

      if (!mounted) return;
      // Use batch event — saves all atomically, emits once
      context.read<FlashcardBloc>().add(AddFlashcards(newCards));

      final msg = skipped > 0
          ? 'Added ${newCards.length} cards to "${deck.name}" ($skipped duplicate${skipped == 1 ? '' : 's'} skipped) ✓'
          : 'Added ${newCards.length} cards to "${deck.name}" ✓';
      if (mounted) {
        _snack(msg);
        Navigator.pop(context);
      }
    } else {
      // ── Create new deck ──────────────────────────────────────────────────
      final topic = _fileText != null
          ? (_fileName ?? 'Uploaded Document')
          : _topicController.text.trim();

      final deckName = _toTitleCase(topic);
      final deckId = const Uuid().v4();

      final deck = Deck(
        id: deckId,
        name: deckName,
        description: 'Generated by AI from: $topic',
        createdAt: now,
        updatedAt: now,
      );

      final flashcards = cards
          .map(
            (card) => Flashcard(
              id: const Uuid().v4(),
              deckId: deckId,
              front: card.front,
              back: card.back,
              createdAt: now,
              updatedAt: now,
            ),
          )
          .toList();

      if (!mounted) return;
      context.read<DeckBloc>().add(AddDeck(deck));
      // Use batch event — saves all atomically, emits once
      context.read<FlashcardBloc>().add(AddFlashcards(flashcards));

      if (mounted) {
        _snack('Deck "$deckName" saved with ${flashcards.length} cards ✓');
        Navigator.pop(context);
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _toTitleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasSuggestions = _suggestions.isNotEmpty;
    final visibleCount = _suggestions.where((c) => !c.removed).length;
    final decks = context.watch<DeckBloc>().state;
    final deckList = decks is DeckLoaded ? decks.decks : <Deck>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate with AI'),
        actions: [
          if (hasSuggestions)
            FilledButton.icon(
              onPressed: _loading ? null : _saveDeck,
              icon: const Icon(Icons.save_outlined),
              label: Text('Save ($visibleCount)'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Topic input ──────────────────────────────────────
                      Text(
                        'Describe your topic',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _topicController,
                          enabled: _fileText == null && !_loading,
                          decoration: InputDecoration(
                            hintText: 'e.g. CVC words for a beginning reader',
                            prefixIcon: const Icon(Icons.lightbulb_outline),
                            suffixIcon: _topicController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => setState(
                                      () => _topicController.clear(),
                                    ),
                                  )
                                : null,
                          ),
                          maxLines: 2,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter a topic or upload a file'
                              : null,
                        ),
                      ),

                      // ── OR divider ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(color: cs.outline),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ),

                      // ── File upload ──────────────────────────────────────
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _pickFile,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(
                          _fileName != null
                              ? _fileName!
                              : 'Upload .txt or .md file',
                        ),
                      ),
                      if (_fileName != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '$_fileName loaded — ${_fileText!.length} characters',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.outline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setState(() {
                                _fileName = null;
                                _fileText = null;
                              }),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── Card count slider ────────────────────────────────
                      Row(
                        children: [
                          Text(
                            'Cards to generate',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _loading ? null : () async {
                              final ctrl = TextEditingController(
                                text: '$_cardCount',
                              );
                              final result = await showDialog<int>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Cards to generate'),
                                  content: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: '1 – 100',
                                      suffixText: 'cards',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        final n = int.tryParse(ctrl.text.trim());
                                        if (n != null && n >= 1 && n <= 100) {
                                          Navigator.pop(context, n);
                                        }
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              if (result != null) {
                                setState(() => _cardCount = result);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$_cardCount',
                                    style: TextStyle(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 13,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _cardCount.toDouble().clamp(1, 100),
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: '$_cardCount',
                        onChanged: _loading
                            ? null
                            : (v) => setState(() => _cardCount = v.round()),
                      ),

                      const SizedBox(height: 4),

                      // ── Capitalise toggle ────────────────────────────────
                      Row(
                        children: [
                          Text(
                            'Capitalise first letter',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Switch(
                            value: _capitalise,
                            onChanged: _loading
                                ? null
                                : (v) => setState(() => _capitalise = v),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // ── Add to existing deck ─────────────────────────────
                      if (deckList.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              'Save to',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<Deck?>(
                                value: _targetDeck,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<Deck?>(
                                    value: null,
                                    child: Text('New deck'),
                                  ),
                                  ...deckList.map(
                                    (d) => DropdownMenuItem<Deck?>(
                                      value: d,
                                      child: Text(
                                        d.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: _loading
                                    ? null
                                    : (v) => setState(() => _targetDeck = v),
                              ),
                            ),
                          ],
                        ),
                        if (_targetDeck != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Duplicates will be skipped automatically.',
                              style: TextStyle(fontSize: 11, color: cs.outline),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],

                      // ── Generate / Regenerate button ─────────────────────
                      FilledButton.icon(
                        onPressed: _loading ? null : _generate,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(
                          hasSuggestions ? 'Regenerate' : 'Generate Cards',
                        ),
                      ),

                      if (hasSuggestions) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              'Preview — tap ✕ to remove a card',
                              style: TextStyle(fontSize: 12, color: cs.outline),
                            ),
                            const Spacer(),
                            Text(
                              '$visibleCount cards',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Card preview list ────────────────────────────────────────
              if (hasSuggestions)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverList.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, i) {
                      final card = _suggestions[i];
                      if (card.removed) return const SizedBox.shrink();
                      return _PreviewCard(
                        card: card,
                        index: i + 1,
                        onRemove: () =>
                            setState(() => _suggestions[i].removed = true),
                        onEditFront: (v) => _suggestions[i].front = v,
                        onEditBack: (v) => _suggestions[i].back = v,
                      );
                    },
                  ),
                ),

              // ── Load More button ─────────────────────────────────────────
              if (hasSuggestions && _fileText == null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _loadMore,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Load More Cards'),
                    ),
                  ),
                ),
            ],
          ),

          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Generating cards…',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Mutable card model for preview ──────────────────────────────────────────

class _EditableCard {
  String front;
  String back;
  // ignore: avoid_positional_boolean_parameters
  bool removed = false;
  _EditableCard({required this.front, required this.back});
}

// ── Preview card widget ──────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final _EditableCard card;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<String> onEditFront;
  final ValueChanged<String> onEditBack;

  const _PreviewCard({
    required this.card,
    required this.index,
    required this.onRemove,
    required this.onEditFront,
    required this.onEditBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card number badge
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 10),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InlineEditField(
                    value: card.front,
                    accentColor: cs.primary,
                    onChanged: onEditFront,
                  ),
                  const SizedBox(height: 6),
                  _InlineEditField(
                    value: card.back,
                    accentColor: cs.secondary,
                    onChanged: onEditBack,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: cs.outline),
              onPressed: onRemove,
              tooltip: 'Remove card',
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEditField extends StatefulWidget {
  final String value;
  final Color accentColor;
  final ValueChanged<String> onChanged;
  const _InlineEditField({
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<_InlineEditField> createState() => _InlineEditFieldState();
}

class _InlineEditFieldState extends State<_InlineEditField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: widget.accentColor, width: 3),
        ),
      ),
      padding: const EdgeInsets.only(left: 8),
      child: TextFormField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        ),
        minLines: 1,
        maxLines: 3,
      ),
    );
  }
}
