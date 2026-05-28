import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../blocs/flashcard/flashcard_bloc.dart';
import '../../blocs/flashcard/flashcard_event.dart';
import '../../blocs/flashcard/flashcard_state.dart';
import '../../blocs/import_export/import_export_bloc.dart';
import '../../blocs/import_export/import_export_event.dart';
import '../../blocs/import_export/import_export_state.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../services/gemini_key_service.dart';
import '../study/study_screen.dart';
import '../study/study_mode_picker_sheet.dart';
import 'flashcard_form_screen.dart';
import '../decks/share_deck_dialog.dart';

class FlashcardListScreen extends StatefulWidget {
  final Deck deck;
  const FlashcardListScreen({super.key, required this.deck});

  @override
  State<FlashcardListScreen> createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  bool _hasGeminiKey = false;

  @override
  void initState() {
    super.initState();
    context.read<FlashcardBloc>().add(LoadFlashcards(widget.deck.id));
    _checkGeminiKey();
  }

  Future<void> _checkGeminiKey() async {
    final has = await GeminiKeyService().hasKey();
    if (mounted) setState(() => _hasGeminiKey = has);
  }

  Deck get deck => widget.deck;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Show export success/error feedback as a SnackBar.
        BlocListener<ImportExportBloc, ImportExportState>(
          listener: (context, state) {
            if (state is ImportExportSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is ImportExportError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        ),
        // Show AI regeneration errors as a SnackBar.
        BlocListener<FlashcardBloc, FlashcardState>(
          listenWhen: (prev, curr) =>
              curr is FlashcardLoaded &&
              curr.regenerateError != null &&
              (prev is! FlashcardLoaded ||
                  prev.regenerateError != curr.regenerateError),
          listener: (context, state) {
            if (state is FlashcardLoaded && state.regenerateError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.regenerateError!),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(deck.name),
          actions: [
            BlocBuilder<FlashcardBloc, FlashcardState>(
              builder: (context, state) {
                if (state is FlashcardLoaded && state.flashcards.isNotEmpty) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow_outlined),
                        tooltip: 'Study',
                        onPressed: () =>
                            _pickModeAndStudy(context, state.flashcards),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.share_outlined),
                        tooltip: 'Share / Export Deck',
                        onSelected: (value) {
                          if (value == 'share_link') {
                            showShareDeckSheet(
                              context,
                              deck: deck,
                              cards: state.flashcards,
                            );
                          } else {
                            context.read<ImportExportBloc>().add(
                              ExportDeckRequested(
                                deck: deck,
                                cards: state.flashcards,
                                format: value,
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'share_link',
                            child: ListTile(
                              leading: Icon(Icons.link_outlined),
                              title: Text('Share via Link'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'json',
                            child: Text('Export as JSON'),
                          ),
                          PopupMenuItem(
                            value: 'csv',
                            child: Text('Export as CSV'),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<FlashcardBloc, FlashcardState>(
          builder: (context, state) {
            if (state is FlashcardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is FlashcardError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is FlashcardLoaded) {
              if (state.flashcards.isEmpty) {
                return _EmptyState(deck: deck);
              }
              final active = state.flashcards.where((c) => !c.archived).toList()
                ..sort((a, b) => a.starCount.compareTo(b.starCount));
              final archived = state.flashcards
                  .where((c) => c.archived)
                  .toList();
              return Column(
                children: [
                  _SwipeHintBanner(
                    message: _hasGeminiKey
                        ? 'Swipe left to edit, rewrite with AI, or delete'
                        : 'Swipe left on a card to edit or delete',
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final card in active)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _CardTile(
                              card: card,
                              deck: deck,
                              hasGeminiKey: _hasGeminiKey,
                              isRegenerating: state.regeneratingIds.contains(
                                card.id,
                              ),
                            ),
                          ),
                        if (archived.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _ArchivedHeader(count: archived.length),
                          const SizedBox(height: 8),
                          for (final card in archived)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ArchivedCardTile(card: card, deck: deck),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<FlashcardBloc>(),
                child: FlashcardFormScreen(deckId: deck.id),
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add Card'),
        ),
      ), // Scaffold
    ); // MultiBlocListener
  }

  Future<void> _pickModeAndStudy(
    BuildContext context,
    List<Flashcard> cards,
  ) async {
    // Exclude archived cards from study sessions.
    final studyCards = cards.where((c) => !c.archived).toList();
    final selection = await StudyModePickerSheet.show(context);
    if (selection == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(
          deck: deck,
          flashcards: studyCards,
          randomize: selection.randomize,
          flipped: selection.flipped,
          mode: selection.mode,
          tolerantMatching: selection.tolerantMatching,
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final Flashcard card;
  final Deck deck;
  final bool hasGeminiKey;
  final bool isRegenerating;

  const _CardTile({
    required this.card,
    required this.deck,
    this.hasGeminiKey = false,
    this.isRegenerating = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Slidable(
      key: ValueKey(card.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<FlashcardBloc>(),
                  child: FlashcardFormScreen(deckId: deck.id, flashcard: card),
                ),
              ),
            ),
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            icon: Icons.edit_outlined,
            label: 'Edit',
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
          ),
          if (hasGeminiKey)
            SlidableAction(
              // Disable tap while an AI call is already in-flight for this card.
              onPressed: isRegenerating
                  ? null
                  : (_) => context.read<FlashcardBloc>().add(
                      RegenerateFlashcard(card.id),
                    ),
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
              icon: Icons.auto_awesome,
              label: 'Rewrite',
            ),
          SlidableAction(
            onPressed: (_) {
              context.read<FlashcardBloc>().add(DeleteFlashcard(card.id));
            },
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Stack(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.front_hand_outlined,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Front',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      _StarButton(card: card),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.front,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.flip_outlined,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(card.back),
                ],
              ),
            ),
          ),
          // Per-card spinner overlay while an AI rewrite is in-flight.
          if (isRegenerating)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Deck deck;
  const _EmptyState({required this.deck});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No cards in "${deck.name}"',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "+ Add Card" to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeHintBanner extends StatelessWidget {
  final String message;
  const _SwipeHintBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cs.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.swipe_left_outlined, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Star button: tap to add a star; 3 stars → card is archived ──────────────
class _StarButton extends StatelessWidget {
  final Flashcard card;
  const _StarButton({required this.card});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const maxStars = 3;
    final stars = card.starCount.clamp(0, maxStars);
    return GestureDetector(
      onTap: () => context.read<FlashcardBloc>().add(StarCard(card.id)),
      child: Tooltip(
        message: 'I know this! (${card.starCount}/3 — at 3 it\'s archived)',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < maxStars; i++)
              Icon(
                i < stars ? Icons.star : Icons.star_border,
                size: 16,
                color: i < stars ? cs.primary : cs.outlineVariant,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Header divider for the archived section ──────────────────────────────────
class _ArchivedHeader extends StatelessWidget {
  final int count;
  const _ArchivedHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.archive_outlined, size: 16, color: cs.outline),
        const SizedBox(width: 6),
        Text(
          'Archived — Mastered ($count)',
          style: TextStyle(
            color: cs.outline,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ],
    );
  }
}

// ── Archived card row — swipeable with Edit, Delete, Unarchive actions ──────
class _ArchivedCardTile extends StatelessWidget {
  final Flashcard card;
  final Deck deck;
  const _ArchivedCardTile({required this.card, required this.deck});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Slidable(
      key: ValueKey('archived_${card.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<FlashcardBloc>(),
                  child: FlashcardFormScreen(deckId: deck.id, flashcard: card),
                ),
              ),
            ),
            backgroundColor: cs.secondary,
            foregroundColor: cs.onSecondary,
            icon: Icons.edit_outlined,
            label: 'Edit',
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) =>
                context.read<FlashcardBloc>().add(DeleteFlashcard(card.id)),
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            icon: Icons.delete_outline,
            label: 'Delete',
          ),
          SlidableAction(
            onPressed: (_) =>
                context.read<FlashcardBloc>().add(UnarchiveCard(card.id)),
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            icon: Icons.unarchive_outlined,
            label: 'Unarchive',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Card(
        color: cs.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.archive_outlined, size: 16, color: cs.outline),
                  const SizedBox(width: 6),
                  Text(
                    'Archived',
                    style: TextStyle(
                      color: cs.outline,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  // Show mastered star badge — 3 filled stars
                  Icon(Icons.star, size: 16, color: cs.outline),
                  Icon(Icons.star, size: 16, color: cs.outline),
                  Icon(Icons.star, size: 16, color: cs.outline),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                card.front,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Divider(height: 16),
              Text(card.back, style: TextStyle(color: cs.outline)),
            ],
          ),
        ),
      ),
    );
  }
}
