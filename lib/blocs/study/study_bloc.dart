import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/flashcard.dart';
import 'study_event.dart';
import 'study_state.dart';

class StudyBloc extends Bloc<StudyEvent, StudyState> {
  List<Flashcard> _originalCards = [];

  StudyBloc() : super(StudyInitial()) {
    on<StartStudySession>(_onStartStudySession);
    on<FlipCard>(_onFlipCard);
    on<NextCard>(_onNextCard);
    on<PreviousCard>(_onPreviousCard);
    on<RestartSession>(_onRestartSession);
  }

  void _onStartStudySession(StartStudySession event, Emitter<StudyState> emit) {
    if (event.flashcards.isEmpty) {
      emit(StudyEmpty());
      return;
    }
    _originalCards = List.from(event.flashcards);
    final cards = event.randomize
        ? (List<Flashcard>.from(event.flashcards)..shuffle(Random()))
        : List<Flashcard>.from(event.flashcards);
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
    final cards = event.randomize
        ? (List<Flashcard>.from(_originalCards)..shuffle(Random()))
        : List<Flashcard>.from(_originalCards);
    emit(StudyInProgress(cards: cards, currentIndex: 0));
  }
}
