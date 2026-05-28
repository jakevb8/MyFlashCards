import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../blocs/analytics/analytics_bloc.dart';
import '../../blocs/analytics/analytics_event.dart';
import '../../blocs/flashcard/flashcard_bloc.dart';
import '../../blocs/flashcard/flashcard_event.dart';
import '../../blocs/flashcard/flashcard_state.dart';
import '../../blocs/study/study_bloc.dart';
import '../../blocs/study/study_event.dart';
import '../../blocs/study/study_state.dart';
import '../../core/notification_prefs_keys.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../models/study_mode.dart';
import '../../repositories/flashcard_repository.dart';
import '../../repositories/study_session_repository.dart';
import '../../services/notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudyScreen extends StatelessWidget {
  final Deck deck;
  final List<Flashcard> flashcards;
  final bool randomize;
  final bool flipped;
  final StudyMode mode;
  final bool tolerantMatching;

  const StudyScreen({
    super.key,
    required this.deck,
    required this.flashcards,
    this.randomize = false,
    this.flipped = false,
    this.mode = StudyMode.flashcard,
    this.tolerantMatching = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          StudyBloc(
            flashcardRepository: context.read<FlashcardRepository>(),
            sessionRepository: context.read<StudySessionRepository>(),
          )..add(
            StartStudySession(
              flashcards: flashcards,
              randomize: randomize,
              flipped: flipped,
              mode: mode,
              tolerantMatching: tolerantMatching,
            ),
          ),
      child: MultiBlocListener(
        listeners: [
          // Refresh analytics so the streak chip and analytics screen update
          // immediately after the session completes.
          BlocListener<StudyBloc, StudyState>(
            listenWhen: (_, s) => s is StudyComplete,
            listener: (context, _) =>
                context.read<AnalyticsBloc>().add(const LoadAnalytics()),
          ),
          // Reschedule the daily reminder with a fresh due-card count so the
          // next notification body reflects cards that were just reviewed.
          BlocListener<StudyBloc, StudyState>(
            listenWhen: (_, s) => s is StudyComplete,
            listener: (context, _) async {
              // Capture context-dependent values before any async gap.
              final cardRepo = context.read<FlashcardRepository>();
              final notifService = context.read<NotificationService>();
              final prefs = await SharedPreferences.getInstance();
              final enabled = prefs.getBool(kReminderEnabledKey) ?? false;
              if (!enabled) return;
              final hour = prefs.getInt(kReminderHourKey) ?? 9;
              final minute = prefs.getInt(kReminderMinuteKey) ?? 0;
              final dueCount = await cardRepo.countDueCards();
              try {
                await notifService.scheduleDailyReminder(
                  time: TimeOfDay(hour: hour, minute: minute),
                  dueCount: dueCount,
                );
              } on NotificationServiceException {
                // Silent fail — don't interrupt the post-session UI.
              }
            },
          ),
        ],
        child: _StudyView(deck: deck, flashcards: flashcards, flipped: flipped),
      ),
    );
  }
}

class _StudyView extends StatelessWidget {
  final Deck deck;
  final List<Flashcard> flashcards;
  final bool flipped;
  const _StudyView({
    required this.deck,
    required this.flashcards,
    required this.flipped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          IconButton(
            icon: Icon(
              Icons.flip_camera_android_outlined,
              color: flipped ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: flipped
                ? 'Showing back→front (tap to restore)'
                : 'Flip deck (study back→front)',
            onPressed: () => context.read<StudyBloc>().add(
              RestartSession(flipped: !flipped),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle',
            onPressed: () => context.read<StudyBloc>().add(
              RestartSession(randomize: true, flipped: flipped),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: 'Restart',
            onPressed: () =>
                context.read<StudyBloc>().add(RestartSession(flipped: flipped)),
          ),
        ],
      ),
      body: BlocBuilder<StudyBloc, StudyState>(
        builder: (context, state) {
          if (state is StudyEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "You're all caught up!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No cards are due for review right now.\nCome back later.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is StudyComplete) {
            return _CompletionView(
              totalCards: state.totalCards,
              flashcards: flashcards,
            );
          }
          if (state is StudyInProgress) {
            return switch (state.mode) {
              StudyMode.flashcard => _StudyCardView(state: state),
              StudyMode.multipleChoice => _MultipleChoiceCardView(
                key: ValueKey(state.currentIndex),
                state: state,
              ),
              StudyMode.typeAnswer => _TypeAnswerCardView(
                key: ValueKey(state.currentIndex),
                state: state,
              ),
            };
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Flashcard flip mode (original)
// ---------------------------------------------------------------------------

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
    final showingBack = !state.showingFront;

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
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          )
                        : Transform(
                            transform: Matrix4.identity()..rotateY(pi),
                            alignment: Alignment.center,
                            child: _CardFace(
                              text: state.currentCard.back,
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
          if (!showingBack)
            Text(
              'Tap card to flip',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          const SizedBox(height: 16),

          // Rating buttons (shown after flip) or hint to flip
          if (showingBack)
            _RatingBar(cardId: state.currentCard.id)
          else
            const SizedBox(
              height: 48,
            ), // placeholder height to avoid layout jump

          const SizedBox(height: 16),

          // Star button — reads live star count from FlashcardBloc;
          // limited to one star per card per session via StudyBloc.
          BlocBuilder<StudyBloc, StudyState>(
            builder: (context, studyState) {
              if (studyState is! StudyInProgress) {
                return const SizedBox.shrink();
              }
              final cardId = studyState.currentCard.id;
              final alreadyStarred = studyState.isStarredThisSession(cardId);

              return BlocBuilder<FlashcardBloc, FlashcardState>(
                builder: (context, cardState) {
                  Flashcard? live;
                  if (cardState is FlashcardLoaded) {
                    try {
                      live = cardState.flashcards.firstWhere(
                        (c) => c.id == cardId,
                      );
                    } catch (_) {}
                  }
                  live ??= studyState.currentCard;

                  final cs = Theme.of(context).colorScheme;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: alreadyStarred
                            ? 'Already starred this card (${live.starCount}/3)'
                            : 'I know this card! (${live.starCount}/3 — at 3 it\'s archived)',
                        child: FilledButton.tonal(
                          onPressed: alreadyStarred
                              ? null
                              : () {
                                  context.read<FlashcardBloc>().add(
                                    StarCard(cardId),
                                  );
                                  context.read<StudyBloc>().add(
                                    MarkStarredInSession(cardId),
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: alreadyStarred
                                ? cs.primaryContainer
                                : null,
                          ),
                          child: Icon(
                            alreadyStarred ? Icons.star : Icons.star_border,
                            size: 22,
                            color: alreadyStarred
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Multiple choice mode
// ---------------------------------------------------------------------------

class _MultipleChoiceCardView extends StatefulWidget {
  final StudyInProgress state;
  const _MultipleChoiceCardView({super.key, required this.state});

  @override
  State<_MultipleChoiceCardView> createState() =>
      _MultipleChoiceCardViewState();
}

class _MultipleChoiceCardViewState extends State<_MultipleChoiceCardView> {
  String? _selected;

  bool get _answered => _selected != null;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
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

          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              state.currentCard.front,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Answer options
          ...state.choices.map((choice) {
            final isCorrect = choice == state.currentCard.back;
            final isSelected = choice == _selected;
            Color bgColor;
            Color fgColor;
            if (!_answered) {
              bgColor = cs.surfaceContainerHigh;
              fgColor = cs.onSurface;
            } else if (isCorrect) {
              bgColor = const Color(0xFFC8E6C9); // green-100
              fgColor = const Color(0xFF1B5E20); // green-900
            } else if (isSelected) {
              bgColor = cs.errorContainer;
              fgColor = cs.onErrorContainer;
            } else {
              bgColor = cs.surfaceContainerHigh;
              fgColor = cs.onSurface.withValues(alpha: 0.4);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _answered
                      ? null
                      : () {
                          setState(() => _selected = choice);
                          // Capture the bloc reference before the async gap to
                          // satisfy use_build_context_synchronously.
                          final bloc = context.read<StudyBloc>();
                          // Auto-rate and advance after a brief pause so the
                          // user can see the correct/incorrect feedback.
                          Future.delayed(const Duration(milliseconds: 900), () {
                            if (mounted) {
                              bloc.add(
                                RateCard(
                                  cardId: state.currentCard.id,
                                  quality: isCorrect ? 5 : 0,
                                ),
                              );
                            }
                          });
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: fgColor,
                    disabledBackgroundColor: bgColor,
                    disabledForegroundColor: fgColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          choice,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (_answered && isCorrect)
                        const Icon(Icons.check_circle, size: 20)
                      else if (_answered && isSelected && !isCorrect)
                        const Icon(Icons.cancel, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Type-the-answer mode
// ---------------------------------------------------------------------------

// Levenshtein edit distance for tolerant answer matching.
int _editDistance(String a, String b) {
  if (a == b) return 0;
  final m = a.length, n = b.length;
  final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= n; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      dp[i][j] = a[i - 1] == b[j - 1]
          ? dp[i - 1][j - 1]
          : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
    }
  }
  return dp[m][n];
}

/// Returns true when [answer] matches [correct] (case-insensitive trim).
/// With [tolerant] = true, also accepts answers within 2 edit-distance for
/// answers longer than 4 characters.
bool _isAnswerCorrect(String answer, String correct, {required bool tolerant}) {
  final a = answer.trim().toLowerCase();
  final c = correct.trim().toLowerCase();
  if (a == c) return true;
  if (!tolerant) return false;
  return c.length > 4 && _editDistance(a, c) <= 2;
}

class _TypeAnswerCardView extends StatefulWidget {
  final StudyInProgress state;
  const _TypeAnswerCardView({super.key, required this.state});

  @override
  State<_TypeAnswerCardView> createState() => _TypeAnswerCardViewState();
}

class _TypeAnswerCardViewState extends State<_TypeAnswerCardView> {
  final _controller = TextEditingController();
  bool? _correct; // null = not yet submitted

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final correct = _isAnswerCorrect(
      _controller.text,
      widget.state.currentCard.back,
      tolerant: widget.state.tolerantMatching,
    );
    setState(() => _correct = correct);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cs = Theme.of(context).colorScheme;
    final submitted = _correct != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
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

          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              state.currentCard.front,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Answer field + check button (hidden after submission)
          if (!submitted) ...[
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Type your answer…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _controller.text.isNotEmpty ? _submit : null,
                icon: const Icon(Icons.check),
                label: const Text('Check'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],

          // Feedback after submission
          if (submitted) ...[
            // Show what the user typed
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _correct! ? const Color(0xFFC8E6C9) : cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _correct! ? Icons.check_circle : Icons.cancel,
                        color: _correct!
                            ? const Color(0xFF1B5E20)
                            : cs.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _correct! ? 'Correct!' : 'Incorrect',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _correct!
                              ? const Color(0xFF1B5E20)
                              : cs.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                  if (!_correct!) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Your answer: ${_controller.text.trim()}',
                      style: TextStyle(color: cs.onErrorContainer),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Correct answer: ${state.currentCard.back}',
                      style: TextStyle(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.read<StudyBloc>().add(
                  RateCard(
                    cardId: state.currentCard.id,
                    quality: _correct! ? 4 : 0,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

/// Four SM-2 rating buttons shown after the card back is revealed.
/// Tapping a button dispatches [RateCard] which persists the new schedule
/// and advances the session automatically.
class _RatingBar extends StatelessWidget {
  final String cardId;
  const _RatingBar({required this.cardId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RatingButton(
          label: 'Again',
          quality: 0,
          cardId: cardId,
          color: Theme.of(context).colorScheme.errorContainer,
          labelColor: Theme.of(context).colorScheme.onErrorContainer,
        ),
        _RatingButton(
          label: 'Hard',
          quality: 2,
          cardId: cardId,
          color: const Color(0xFFFFE0B2),
          labelColor: const Color(0xFF6D4C41),
        ),
        _RatingButton(
          label: 'Good',
          quality: 3,
          cardId: cardId,
          color: Theme.of(context).colorScheme.primaryContainer,
          labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        _RatingButton(
          label: 'Easy',
          quality: 5,
          cardId: cardId,
          color: const Color(0xFFC8E6C9),
          labelColor: const Color(0xFF2E7D32),
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final int quality;
  final String cardId;
  final Color color;
  final Color labelColor;

  const _RatingButton({
    required this.label,
    required this.quality,
    required this.cardId,
    required this.color,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () => context.read<StudyBloc>().add(
        RateCard(cardId: cardId, quality: quality),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: labelColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _CardFace({
    required this.text,
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
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 20),
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
