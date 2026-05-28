import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../blocs/analytics/analytics_state.dart';
import '../../blocs/analytics/analytics_bloc.dart';
import '../../blocs/deck/deck_bloc.dart';
import '../../blocs/deck/deck_event.dart';
import '../../blocs/deck/deck_state.dart';
import '../../blocs/deck_sharing/deck_sharing_bloc.dart';
import '../../blocs/deck_sharing/deck_sharing_state.dart';
import '../../blocs/import_export/import_export_bloc.dart';
import '../../blocs/import_export/import_export_event.dart';
import '../../blocs/import_export/import_export_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/notification_prefs_keys.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../repositories/flashcard_repository.dart';
import '../../repositories/hive_flashcard_repository.dart';
import '../../widgets/theme_picker_sheet.dart';
import '../cards/flashcard_list_screen.dart';
import '../study/study_mode_picker_sheet.dart';
import '../study/study_screen.dart';
import 'deck_form_screen.dart';
import 'import_export_dialogs.dart';
import 'share_deck_dialog.dart';

/// Deck list home screen.
///
/// Supports multi-select mode (long-press any tile to enter) for bundled study
/// sessions spanning multiple decks. While selecting, the app bar switches to a
/// selection toolbar and the FAB is hidden.
class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  // Multi-select state — kept local because it is purely UI; no bloc needed.
  bool _multiSelectMode = false;
  final Set<String> _selectedDeckIds = {};

  void _enterMultiSelect(String deckId) {
    setState(() {
      _multiSelectMode = true;
      _selectedDeckIds.add(deckId);
    });
  }

  void _toggleSelection(String deckId) {
    setState(() {
      if (_selectedDeckIds.contains(deckId)) {
        _selectedDeckIds.remove(deckId);
        if (_selectedDeckIds.isEmpty) _multiSelectMode = false;
      } else {
        _selectedDeckIds.add(deckId);
      }
    });
  }

  void _cancelMultiSelect() {
    setState(() {
      _multiSelectMode = false;
      _selectedDeckIds.clear();
    });
  }

  /// Fetches cards for all selected decks, shows the mode picker, then
  /// navigates to a merged study session.
  Future<void> _studySelectedDecks(
    BuildContext context,
    List<Deck> allDecks,
  ) async {
    final selectedDecks = allDecks
        .where((d) => _selectedDeckIds.contains(d.id))
        .toList();

    final cardRepo = context.read<FlashcardRepository>();
    final allCards = await cardRepo.getFlashcardsByDecks(
      selectedDecks.map((d) => d.id).toList(),
    );
    // Exclude archived cards — StudyBloc will further filter to due-only.
    final studyCards = allCards.where((c) => !c.archived).toList();

    if (!context.mounted) return;

    final selection = await StudyModePickerSheet.show(context);
    if (selection == null || !context.mounted) return;

    // Clear selection before navigating so the screen is clean on back.
    _cancelMultiSelect();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(
          decks: selectedDecks,
          flashcards: studyCards,
          randomize: selection.randomize,
          flipped: selection.flipped,
          mode: selection.mode,
          tolerantMatching: selection.tolerantMatching,
        ),
      ),
    );
  }

  void _showAddDeckSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeckFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // MultiBlocListener handles import feedback and sharing errors.
    return MultiBlocListener(
      listeners: [
        BlocListener<ImportExportBloc, ImportExportState>(
          listener: (context, state) async {
            if (state is ImportDuplicateDetected) {
              final action = await showDuplicateDeckDialog(
                context,
                deckName: state.existingDeck.name,
              );
              if (!context.mounted) return;
              switch (action) {
                case ImportDuplicateAction.replace:
                  context.read<ImportExportBloc>().add(
                    ImportConfirmReplace(state.incoming),
                  );
                case ImportDuplicateAction.merge:
                  context.read<ImportExportBloc>().add(
                    ImportConfirmMerge(
                      bundle: state.incoming,
                      existingDeck: state.existingDeck,
                    ),
                  );
                case ImportDuplicateAction.cancel:
                  context.read<ImportExportBloc>().add(ImportCancelled());
              }
            } else if (state is ImportExportSuccess) {
              context.read<DeckBloc>().add(LoadDecks());
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
        BlocListener<DeckSharingBloc, DeckSharingState>(
          listener: (context, state) {
            if (state is DeckSharingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        ),
      ],
      // BlocBuilder wraps the whole Scaffold so the AppBar can react to both
      // deck list state (for the Study Selected action) and multi-select state.
      child: BlocBuilder<DeckBloc, DeckState>(
        builder: (context, deckState) {
          return Scaffold(
            appBar: _multiSelectMode
                ? AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancel selection',
                      onPressed: _cancelMultiSelect,
                    ),
                    title: Text('${_selectedDeckIds.length} selected'),
                    actions: [
                      if (_selectedDeckIds.length >= 2 &&
                          deckState is DeckLoaded)
                        TextButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Study Selected'),
                          onPressed: () =>
                              _studySelectedDecks(context, deckState.decks),
                        ),
                    ],
                  )
                : AppBar(
                    title: const Text('My Flashcard Decks'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.bar_chart_outlined),
                        tooltip: 'Study Analytics',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/analytics'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'Settings',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/settings'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome_outlined),
                        tooltip: 'Generate with AI',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/generate'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.palette_outlined),
                        tooltip: 'Change Theme',
                        onPressed: () => ThemePickerSheet.show(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cloud_upload_outlined),
                        tooltip: 'Backup to Cloud',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/backup'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_upload_outlined),
                        tooltip: 'Import Deck',
                        onPressed: () => context.read<ImportExportBloc>().add(
                          ImportDeckRequested(),
                        ),
                      ),
                    ],
                  ),
            body: _buildBody(context, deckState),
            floatingActionButton: _multiSelectMode
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => _showAddDeckSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New Deck'),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, DeckState state) {
    if (state is DeckLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is DeckError) {
      return Center(child: Text('Error: ${state.message}'));
    }
    if (state is DeckLoaded) {
      if (state.decks.isEmpty) {
        return _EmptyState();
      }
      // All unique tags across every deck — used for the filter bar.
      final allTags = state.decks.expand((d) => d.tags).toSet().toList()
        ..sort();
      // Decks to display after applying the active tag filter.
      final displayedDecks = state.selectedTag == null
          ? state.decks
          : state.decks
                .where((d) => d.tags.contains(state.selectedTag))
                .toList();
      return Column(
        children: [
          if (allTags.isNotEmpty && !_multiSelectMode)
            _TagFilterBar(allTags: allTags, selectedTag: state.selectedTag),
          if (!_multiSelectMode) ...[_StreakBanner(), _DailyGoalBanner()],
          if (!_multiSelectMode)
            _SwipeHintBanner(message: 'Swipe left on a deck to edit or delete')
          else
            _SwipeHintBanner(
              message: 'Long-press to select; tap Study Selected to study',
            ),
          Expanded(
            child: displayedDecks.isEmpty
                ? Center(
                    child: Text(
                      'No decks tagged "${state.selectedTag}"',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedDecks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final deck = displayedDecks[index];
                      return _DeckTile(
                        deck: deck,
                        isMultiSelectMode: _multiSelectMode,
                        isSelected: _selectedDeckIds.contains(deck.id),
                        onLongPress: () => _enterMultiSelect(deck.id),
                        onToggleSelect: () => _toggleSelection(deck.id),
                      );
                    },
                  ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

/// Streak badge shown above the deck list. Hidden when streak is 0 or data
/// is not yet loaded, to avoid a blank bar on first launch.
class _StreakBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is! AnalyticsLoaded || state.streak == 0) {
          return const SizedBox.shrink();
        }
        final cs = Theme.of(context).colorScheme;
        return InkWell(
          onTap: () => Navigator.pushNamed(context, '/analytics'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: cs.primaryContainer,
            child: Row(
              children: [
                Icon(Icons.local_fire_department, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  '${state.streak} day streak! Keep it up ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text('🔥'),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: cs.onPrimaryContainer,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Goal progress banner shown below the streak banner.
///
/// Reads [cardsReviewedToday] from [AnalyticsBloc] and the daily goal from
/// SharedPreferences. Hidden when the goal is not set or analytics are loading.
/// Tapping navigates to the analytics screen.
class _DailyGoalBanner extends StatefulWidget {
  @override
  State<_DailyGoalBanner> createState() => _DailyGoalBannerState();
}

class _DailyGoalBannerState extends State<_DailyGoalBanner> {
  int _dailyGoal = 10;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _dailyGoal = prefs.getInt(kDailyGoalKey) ?? 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is! AnalyticsLoaded) return const SizedBox.shrink();
        final reviewed = state.cardsReviewedToday;
        final goal = _dailyGoal;
        final progress = (reviewed / goal).clamp(0.0, 1.0);
        final done = reviewed >= goal;
        final cs = Theme.of(context).colorScheme;
        return InkWell(
          onTap: () => Navigator.pushNamed(context, '/analytics'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: cs.secondaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.flag_outlined,
                      size: 16,
                      color: done ? cs.secondary : cs.onSecondaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      done
                          ? 'Daily goal reached! ($reviewed / $goal)'
                          : '$reviewed / $goal cards today',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: cs.onSecondaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: cs.secondary.withAlpha(40),
                    color: done ? cs.secondary : cs.secondary,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeckTile extends StatefulWidget {
  final Deck deck;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onLongPress;
  final VoidCallback onToggleSelect;

  const _DeckTile({
    required this.deck,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    required this.onLongPress,
    required this.onToggleSelect,
  });

  @override
  State<_DeckTile> createState() => _DeckTileState();
}

class _DeckTileState extends State<_DeckTile> {
  late Future<_DeckStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  /// Loads the stats for this deck from the flashcard repository.
  ///
  /// Using initState rather than a builder-level FutureBuilder.future so the
  /// future is not recreated on every rebuild (which would cause a loading
  /// flash on every parent list rebuild).
  Future<_DeckStats> _loadStats() async {
    final repo = context.read<FlashcardRepository>();
    final cards = await repo.getFlashcards(widget.deck.id);
    return _DeckStats.fromCards(cards);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final card = Card(
      // Highlight selected tiles with a tinted background.
      color: widget.isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: widget.isMultiSelectMode
            ? Checkbox(
                value: widget.isSelected,
                onChanged: (_) => widget.onToggleSelect(),
              )
            : CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  widget.deck.name.isNotEmpty
                      ? widget.deck.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        title: Text(
          widget.deck.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.deck.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(widget.deck.description),
              ),
            FutureBuilder<_DeckStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return _DeckProgressRow(stats: snapshot.data!);
              },
            ),
            if (widget.deck.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    for (final tag in widget.deck.tags)
                      Chip(
                        label: Text(tag),
                        labelStyle: Theme.of(context).textTheme.labelSmall,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
          ],
        ),
        trailing: widget.isMultiSelectMode
            ? null
            : const Icon(Icons.chevron_right),
        onTap: widget.isMultiSelectMode
            ? widget.onToggleSelect
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FlashcardListScreen(deck: widget.deck),
                ),
              ),
        onLongPress: widget.isMultiSelectMode ? null : widget.onLongPress,
      ),
    );

    // Disable swipe actions during multi-select to prevent accidental deletion.
    if (widget.isMultiSelectMode) return card;

    return Slidable(
      key: ValueKey(widget.deck.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _shareViaLink(context),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: Icons.link_outlined,
            label: 'Share',
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeckFormScreen(deck: widget.deck),
              ),
            ),
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            icon: Icons.edit_outlined,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
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
      child: card,
    );
  }

  Future<void> _shareViaLink(BuildContext context) async {
    final repo = context.read<HiveFlashcardRepository>();
    final cards = await repo.getFlashcards(widget.deck.id);
    if (!context.mounted) return;
    await showShareDeckSheet(context, deck: widget.deck, cards: cards);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Deck'),
        content: Text('Delete "${widget.deck.name}" and all its cards?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              context.read<DeckBloc>().add(DeleteDeck(widget.deck.id));
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Aggregated progress metrics for a single deck, computed from its card list.
class _DeckStats {
  final int dueToday;
  final int activeCards;
  final int masteredCards;

  const _DeckStats({
    required this.dueToday,
    required this.activeCards,
    required this.masteredCards,
  });

  /// Computes stats from a full card list (archived + active mixed).
  factory _DeckStats.fromCards(List<Flashcard> cards) {
    final now = DateTime.now();
    int due = 0;
    int active = 0;
    int mastered = 0;
    for (final c in cards) {
      if (c.archived) {
        mastered++;
      } else {
        active++;
        if (c.nextReviewAt == null || !c.nextReviewAt!.isAfter(now)) due++;
      }
    }
    return _DeckStats(
      dueToday: due,
      activeCards: active,
      masteredCards: mastered,
    );
  }

  bool get allCaughtUp => dueToday == 0 && activeCards > 0;
  bool get isEmpty => activeCards == 0 && masteredCards == 0;
}

/// A compact row of stat chips shown below the deck name in each deck tile.
class _DeckProgressRow extends StatelessWidget {
  final _DeckStats stats;
  const _DeckProgressRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall;

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        if (stats.allCaughtUp)
          _StatChip(
            icon: Icons.check_circle_outline,
            label: 'All caught up',
            color: cs.primary,
            textStyle: textStyle,
          )
        else if (stats.dueToday > 0)
          _StatChip(
            icon: Icons.schedule_outlined,
            label: '${stats.dueToday} due',
            color: cs.error,
            textStyle: textStyle,
          ),
        if (stats.activeCards > 0)
          _StatChip(
            icon: Icons.layers_outlined,
            label: '${stats.activeCards} active',
            color: cs.secondary,
            textStyle: textStyle,
          ),
        if (stats.masteredCards > 0)
          _StatChip(
            icon: Icons.star_outline,
            label: '${stats.masteredCards} mastered',
            color: cs.tertiary,
            textStyle: textStyle,
          ),
      ],
    );
  }
}

/// A single icon + label chip used in the deck progress row.
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final TextStyle? textStyle;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(label, style: textStyle?.copyWith(color: color)),
      ],
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.layers_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No decks yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create your first deck',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tag filter bar — horizontal scrollable row of FilterChips
// ---------------------------------------------------------------------------

/// Shown above the deck list when at least one deck has tags.
///
/// "All" clears the filter; each tag chip filters to matching decks.
class _TagFilterBar extends StatelessWidget {
  final List<String> allTags;
  final String? selectedTag;

  const _TagFilterBar({required this.allTags, required this.selectedTag});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: selectedTag == null,
            onSelected: (_) =>
                context.read<DeckBloc>().add(const FilterDecksByTag(null)),
          ),
          for (final tag in allTags) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(tag),
              selected: selectedTag == tag,
              onSelected: (_) =>
                  context.read<DeckBloc>().add(FilterDecksByTag(tag)),
            ),
          ],
        ],
      ),
    );
  }
}
