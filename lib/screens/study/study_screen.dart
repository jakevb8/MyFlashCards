import 'dart:math';
import 'package:flutter/material.dart';
import '../../blocs/study/study_bloc.dart';
import '../../blocs/study/study_event.dart';
import '../../blocs/study/study_state.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudyScreen extends StatelessWidget {
  final Deck deck;
  final List<Flashcard> flashcards;
  final bool randomize;

  const StudyScreen({
    super.key,
    required this.deck,
    required this.flashcards,
    this.randomize = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StudyBloc()
        ..add(StartStudySession(flashcards: flashcards, randomize: randomize)),
      child: _StudyView(deck: deck, flashcards: flashcards),
    );
  }
}

class _StudyView extends StatelessWidget {
  final Deck deck;
  final List<Flashcard> flashcards;
  const _StudyView({required this.deck, required this.flashcards});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle',
            onPressed: () => context.read<StudyBloc>().add(
              const RestartSession(randomize: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: 'Restart',
            onPressed: () => context.read<StudyBloc>().add(
              const RestartSession(randomize: false),
            ),
          ),
        ],
      ),
      body: BlocBuilder<StudyBloc, StudyState>(
        builder: (context, state) {
          if (state is StudyEmpty) {
            return const Center(child: Text('No cards to study.'));
          }
          if (state is StudyComplete) {
            return _CompletionView(
              totalCards: state.totalCards,
              flashcards: flashcards,
            );
          }
          if (state is StudyInProgress) {
            return _StudyCardView(state: state);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _StudyCardView extends StatefulWidget {
  final StudyInProgress state;
  const _StudyCardView({required this.state});

  @override
  State<_StudyCardView> createState() => _StudyCardViewState();
}

class _StudyCardViewState extends State<_StudyCardView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_StudyCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentIndex != widget.state.currentIndex) {
      _controller.reset();
    }
    if (widget.state.showingFront != oldWidget.state.showingFront) {
      if (widget.state.showingFront) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress
          LinearProgressIndicator(
            value: (state.currentIndex + 1) / state.totalCards,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            '${state.currentIndex + 1} / ${state.totalCards}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          // Card
          Expanded(
            child: GestureDetector(
              onTap: () => context.read<StudyBloc>().add(FlipCard()),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final angle = _animation.value * pi;
                  final isFront = angle <= pi / 2;
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: isFront
                        ? _CardFace(
                            text: state.currentCard.front,
                            label: 'FRONT',
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          )
                        : Transform(
                            transform: Matrix4.identity()..rotateY(pi),
                            alignment: Alignment.center,
                            child: _CardFace(
                              text: state.currentCard.back,
                              label: 'BACK',
                              color: colorScheme.secondaryContainer,
                              textColor: colorScheme.onSecondaryContainer,
                            ),
                          ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Tap card to flip',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: 24),

          // Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.tonal(
                onPressed: state.isFirst
                    ? null
                    : () => context.read<StudyBloc>().add(PreviousCard()),
                child: const Row(
                  children: [Icon(Icons.chevron_left), Text('Previous')],
                ),
              ),
              FilledButton(
                onPressed: () => context.read<StudyBloc>().add(NextCard()),
                child: Row(
                  children: [
                    Text(state.isLast ? 'Finish' : 'Next'),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final String label;
  final Color color;
  final Color textColor;

  const _CardFace({
    required this.text,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  final int totalCards;
  final List<Flashcard> flashcards;
  const _CompletionView({required this.totalCards, required this.flashcards});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Session Complete!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You reviewed $totalCards card${totalCards == 1 ? '' : 's'}.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.read<StudyBloc>().add(
                    const RestartSession(randomize: false),
                  ),
                  icon: const Icon(Icons.replay),
                  label: const Text('Restart'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => context.read<StudyBloc>().add(
                    const RestartSession(randomize: true),
                  ),
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Shuffle & Retry'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Deck'),
            ),
          ],
        ),
      ),
    );
  }
}
