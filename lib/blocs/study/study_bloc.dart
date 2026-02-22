import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/flashcard.dart';
import 'study_event.dart';
import 'study_state.dart';

class StudyBloc extends Bloc<StudyEvent, StudyState> {
  List<Flashcard> _originalCards = [];
  bool _flipped = false;

  StudyBloc() : super(StudyInitial()) {
    on<StartStudySession>(_onStartStudySession);
    on<FlipCard>(_onFlipCard);
    on<NextCard>(_onNextCard);
    on<PreviousCard>(_onPreviousCard);
    on<RestartSession>(_onRestartSession);
    on<MarkStarredInSession>(_onMarkStarredInSession);
  }

  /// Swaps front/back on every card when [flipped] is true.
  List<Flashcard> _applyFlip(List<Flashcard> cards, bool flipped) {
    if (!flipped) return cards;
    return cards.map((c) => c.copyWith(front: c.back, back: c.front)).toList();
  }

  void _onStartStudySession(StartStudySession event, Emitter<StudyState> emit) {
    if (event.flashcards.isEmpty) {
      emit(StudyEmpty());
      return;
    }
    _originalCards = List.from(event.flashcards);
    _flipped = event.flipped;
    var cards = event.randomize
        ? (List<Flashcard>.from(event.flashcards)..shuffle(Random()))
        : List<Flashcard>.from(event.flashcards);
    cards = _applyFlip(cards, _flipped);
    emit(StudyInProgress(cards: cards, currentIndex: 0));
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
        emit(
          current.copyWith(
            currentIndex: current.currentIndex + 1,
            showingFront: true,
          ),
        );
      }
    }
  }

  void _onPreviousCard(PreviousCard event, Emitter<StudyState> emit) {
    if (state is StudyInProgress) {
      final current = state as StudyInProgress;
      if (!current.isFirst) {
        emit(
          current.copyWith(
            currentIndex: current.currentIndex - 1,
            showingFront: true,
          ),
        );
      }
    }
  }

  void _onRestartSession(RestartSession event, Emitter<StudyState> emit) {
    if (_originalCards.isEmpty) return;
    _flipped = event.flipped;
    var cards = event.randomize
        ? (List<Flashcard>.from(_originalCards)..shuffle(Random()))
        : List<Flashcard>.from(_originalCards);
    cards = _applyFlip(cards, _flipped);
    emit(StudyInProgress(cards: cards, currentIndex: 0));
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
}
