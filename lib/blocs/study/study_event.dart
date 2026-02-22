import 'package:equatable/equatable.dart';
import '../../models/flashcard.dart';

abstract class StudyEvent extends Equatable {
  const StudyEvent();
  @override
  List<Object?> get props => [];
}

class StartStudySession extends StudyEvent {
  final List<Flashcard> flashcards;
  final bool randomize;
  final bool flipped;
  const StartStudySession({
    required this.flashcards,
    this.randomize = false,
    this.flipped = false,
  });
  @override
  List<Object?> get props => [flashcards, randomize, flipped];
}

class FlipCard extends StudyEvent {}

class NextCard extends StudyEvent {}

class PreviousCard extends StudyEvent {}

class RestartSession extends StudyEvent {
  final bool randomize;
  final bool flipped;
  const RestartSession({this.randomize = false, this.flipped = false});
  @override
  List<Object?> get props => [randomize, flipped];
}
