// StudyBloc — manages an active flashcard study session.
//
// Responsibilities:
//   - Filters the provided card list to only those due today (SM-2 scheduling).
//   - Drives the flip animation state machine (showingFront).
//   - Generates multiple-choice answer options (correct + distractors) for
//     StudyMode.multipleChoice, refreshed on every card advance.
//   - Handles SM-2 ratings: computes new schedule via SpacedRepetitionService,
//     persists to Hive via FlashcardRepository, then advances the session.
//   - Records a StudySession on completion so AnalyticsBloc can compute
//     streaks and accuracy.
//
// Session lifecycle: StudyInitial → StudyInProgress (per card) → StudyComplete.
// StudyEmpty is emitted when no due cards exist at session start.

import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../models/flashcard.dart';
import '../../models/study_mode.dart';
import '../../models/study_session.dart';
import '../../repositories/flashcard_repository.dart';
import '../../repositories/study_session_repository.dart';
import '../../services/spaced_repetition_service.dart';
import 'study_event.dart';
import 'study_state.dart';

class StudyBloc extends Bloc<StudyEvent, StudyState> {
  final FlashcardRepository _flashcardRepository;
  final StudySessionRepository _sessionRepository;
  final SpacedRepetitionService _srService;
  final Uuid _uuid;

  List<Flashcard> _originalCards = [];
  bool _flipped = false;
  StudyMode _mode = StudyMode.flashcard;
  bool _tolerantMatching = false;
  int _sessionCorrectCount = 0;

  // All non-archived deck cards (flipped as needed) used as the MC distractor pool.
  // Wider than _originalCards which only holds today's due cards.
  List<Flashcard> _allCardsFlipped = [];

  StudyBloc({
    required FlashcardRepository flashcardRepository,
    required StudySessionRepository sessionRepository,
    SpacedRepetitionService? srService,
    Uuid? uuid,
  }) : _flashcardRepository = flashcardRepository,
       _sessionRepository = sessionRepository,
       _srService = srService ?? SpacedRepetitionService(),
       _uuid = uuid ?? const Uuid(),
       super(StudyInitial()) {
    on<StartStudySession>(_onStartStudySession);
    on<FlipCard>(_onFlipCard);
    on<NextCard>(_onNextCard);
    on<PreviousCard>(_onPreviousCard);
    on<RestartSession>(_onRestartSession);
    on<MarkStarredInSession>(_onMarkStarredInSession);
    on<RateCard>(_onRateCard);
    on<EditCardInSession>(_onEditCardInSession);
  }

  /// Returns cards due now: new cards (nextReviewAt == null) or overdue cards.
  /// Sorted so new cards come first, then oldest-due first.
  List<Flashcard> _filterDue(List<Flashcard> cards) {
    final now = DateTime.now();
    return cards
        .where((c) => c.nextReviewAt == null || !c.nextReviewAt!.isAfter(now))
        .toList()
      ..sort((a, b) {
        if (a.nextReviewAt == null && b.nextReviewAt == null) return 0;
        if (a.nextReviewAt == null) return -1;
        if (b.nextReviewAt == null) return 1;
        return a.nextReviewAt!.compareTo(b.nextReviewAt!);
      });
  }

  /// Swaps front/back on every card when [flipped] is true.
  List<Flashcard> _applyFlip(List<Flashcard> cards, bool flipped) {
    if (!flipped) return cards;
    return cards.map((c) => c.copyWith(front: c.back, back: c.front)).toList();
  }

  /// Generates MC answer choices for [card]: the correct answer plus up to 3
  /// distractors drawn from [pool]. Returns an empty list for non-MC modes.
  ///
  /// The pool should already have front/back swapped for flipped sessions so
  /// that [card.back] is always the correct answer regardless of flip state.
  List<String> _generateChoices(Flashcard card, List<Flashcard> pool) {
    if (_mode != StudyMode.multipleChoice) return const [];
    final correct = card.back;
    final distractors =
        pool
            .where((c) => c.id != card.id)
            .map((c) => c.back)
            .where((s) => s.trim().isNotEmpty && s != correct)
            .toSet()
            .toList()
          ..shuffle(Random());
    return [correct, ...distractors.take(3)]..shuffle(Random());
  }

  void _onStartStudySession(StartStudySession event, Emitter<StudyState> emit) {
    final due = _filterDue(event.flashcards);
    if (due.isEmpty) {
      emit(StudyEmpty());
      return;
    }
    _originalCards = List.from(due);
    _flipped = event.flipped;
    _mode = event.mode;
    _tolerantMatching = event.tolerantMatching;
    _sessionCorrectCount = 0;

    // Build the distractor pool from all provided cards so MC has plenty of
    // options even when only a few cards are due today.
    _allCardsFlipped = _applyFlip(List.from(event.flashcards), _flipped);

    var cards = event.randomize
        ? (List<Flashcard>.from(due)..shuffle(Random()))
        : List<Flashcard>.from(due);
    cards = _applyFlip(cards, _flipped);

    emit(
      StudyInProgress(
        cards: cards,
        currentIndex: 0,
        mode: _mode,
        choices: _generateChoices(cards.first, _allCardsFlipped),
        tolerantMatching: _tolerantMatching,
      ),
    );
  }

  void _onFlipCard(FlipCard event, Emitter<StudyState> emit) {
    if (state is StudyInProgress) {
      final current = state as StudyInProgress;
      emit(current.copyWith(showingFront: !current.showingFront));
    }
  }

  void _onNextCard(NextCard event, Emitter<StudyState> emit) {
    if (state is StudyInProgress) {
      final current = state as StudyInProgress;
      if (current.isLast) {
        emit(StudyComplete(current.totalCards));
      } else {
        final nextIndex = current.currentIndex + 1;
        emit(
          current.copyWith(
            currentIndex: nextIndex,
            showingFront: true,
            choices: _generateChoices(
              current.cards[nextIndex],
              _allCardsFlipped,
            ),
          ),
        );
      }
    }
  }

  void _onPreviousCard(PreviousCard event, Emitter<StudyState> emit) {
    if (state is StudyInProgress) {
      final current = state as StudyInProgress;
      if (!current.isFirst) {
        final prevIndex = current.currentIndex - 1;
        emit(
          current.copyWith(
            currentIndex: prevIndex,
            showingFront: true,
            choices: _generateChoices(
              current.cards[prevIndex],
              _allCardsFlipped,
            ),
          ),
        );
      }
    }
  }

  void _onRestartSession(RestartSession event, Emitter<StudyState> emit) {
    if (_originalCards.isEmpty) return;
    _flipped = event.flipped;
    _sessionCorrectCount = 0;
    var cards = event.randomize
        ? (List<Flashcard>.from(_originalCards)..shuffle(Random()))
        : List<Flashcard>.from(_originalCards);
    cards = _applyFlip(cards, _flipped);
    // Rebuild distractor pool with the (possibly new) flip orientation.
    _allCardsFlipped = _applyFlip(List.from(_originalCards), _flipped);
    emit(
      StudyInProgress(
        cards: cards,
        currentIndex: 0,
        mode: _mode,
        choices: _generateChoices(cards.first, _allCardsFlipped),
        tolerantMatching: _tolerantMatching,
      ),
    );
  }

  void _onMarkStarredInSession(
    MarkStarredInSession event,
    Emitter<StudyState> emit,
  ) {
    if (state is StudyInProgress) {
      final current = state as StudyInProgress;
      emit(
        current.copyWith(
          starredThisSession: {...current.starredThisSession, event.cardId},
        ),
      );
    }
  }

  /// Applies SM-2 scheduling to the rated card, persists it, then advances.
  ///
  /// The card in session state may have its front/back swapped (flipped mode),
  /// so we look up the original unswapped card from [_originalCards] by ID
  /// before passing it to [SpacedRepetitionService].
  ///
  /// When the last card is rated, a [StudySession] is written to the session
  /// repository so [AnalyticsBloc] can compute up-to-date streak and accuracy.
  Future<void> _onRateCard(RateCard event, Emitter<StudyState> emit) async {
    if (state is! StudyInProgress) return;
    final current = state as StudyInProgress;

    final originalCard = _originalCards.firstWhere(
      (c) => c.id == event.cardId,
      orElse: () => current.currentCard,
    );

    final scheduled = _srService.schedule(originalCard, event.quality);
    await _flashcardRepository.updateFlashcard(scheduled);

    if (event.quality >= 3) _sessionCorrectCount++;

    // Keep _originalCards in sync so RestartSession reflects new schedule data.
    final idx = _originalCards.indexWhere((c) => c.id == event.cardId);
    if (idx >= 0) _originalCards[idx] = scheduled;

    if (current.isLast) {
      await _persistSession(current.totalCards);
      emit(StudyComplete(current.totalCards));
    } else {
      final nextIndex = current.currentIndex + 1;
      emit(
        current.copyWith(
          currentIndex: nextIndex,
          showingFront: true,
          choices: _generateChoices(current.cards[nextIndex], _allCardsFlipped),
        ),
      );
    }
  }

  /// Persists an inline edit made during a session and refreshes in-session state.
  ///
  /// [event.updated] is always the canonical (non-flipped) card. The handler:
  ///   1. Writes to storage via the repository.
  ///   2. Patches [_originalCards] so RestartSession picks up the new text.
  ///   3. Patches [_allCardsFlipped] so the MC distractor pool reflects the edit.
  ///   4. Re-applies the flip transform for the display copy and emits new state.
  Future<void> _onEditCardInSession(
    EditCardInSession event,
    Emitter<StudyState> emit,
  ) async {
    if (state is! StudyInProgress) return;
    final current = state as StudyInProgress;

    await _flashcardRepository.updateFlashcard(event.updated);

    // Patch canonical backup list so restart rebuilds with new text.
    final origIdx = _originalCards.indexWhere((c) => c.id == event.updated.id);
    if (origIdx >= 0) _originalCards[origIdx] = event.updated;

    // Build the display-oriented copy, applying the session flip if active.
    final displayCard = _flipped
        ? event.updated.copyWith(
            front: event.updated.back,
            back: event.updated.front,
          )
        : event.updated;

    // Patch the MC distractor pool so other cards don't see stale answer text.
    final allIdx = _allCardsFlipped.indexWhere((c) => c.id == event.updated.id);
    if (allIdx >= 0) _allCardsFlipped[allIdx] = displayCard;

    final updatedCards = List<Flashcard>.from(current.cards);
    updatedCards[current.currentIndex] = displayCard;

    emit(
      current.copyWith(
        cards: updatedCards,
        choices: _generateChoices(displayCard, _allCardsFlipped),
      ),
    );
  }

  /// Writes a [StudySession] record to the repository for the just-completed session.
  /// Uses today's local midnight as the session date so analytics group by calendar day.
  Future<void> _persistSession(int totalCards) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final session = StudySession(
      id: _uuid.v4(),
      date: today,
      cardsReviewed: totalCards,
      correctCount: _sessionCorrectCount,
    );
    await _sessionRepository.addSession(session);
  }
}
