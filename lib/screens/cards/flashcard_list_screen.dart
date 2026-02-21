import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../blocs/flashcard/flashcard_bloc.dart';
import '../../blocs/flashcard/flashcard_event.dart';
import '../../blocs/flashcard/flashcard_state.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../study/study_screen.dart';
import 'flashcard_form_screen.dart';

class FlashcardListScreen extends StatefulWidget {
  final Deck deck;
  const FlashcardListScreen({super.key, required this.deck});

  @override
  State<FlashcardListScreen> createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FlashcardBloc>().add(LoadFlashcards(widget.deck.id));
  }

  Deck get deck => widget.deck;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          BlocBuilder<FlashcardBloc, FlashcardState>(
            builder: (context, state) {
              if (state is FlashcardLoaded && state.flashcards.isNotEmpty) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow_outlined),
                      tooltip: 'Study In Order',
                      onPressed: () => _startStudy(
                        context,
                        state.flashcards,
                        randomize: false,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      tooltip: 'Study Randomized',
                      onPressed: () => _startStudy(
                        context,
                        state.flashcards,
                        randomize: true,
                      ),
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
            return Column(
              children: [
                _SwipeHintBanner(message: 'Swipe left on a card to edit or delete'),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.flashcards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final card = state.flashcards[index];
                      return _CardTile(card: card, deck: deck);
                    },
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
    );
  }

  void _startStudy(
    BuildContext context,
    List<Flashcard> cards, {
    required bool randomize,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StudyScreen(deck: deck, flashcards: cards, randomize: randomize),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final Flashcard card;
  final Deck deck;
  const _CardTile({required this.card, required this.deck});

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
      child: Card(
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
