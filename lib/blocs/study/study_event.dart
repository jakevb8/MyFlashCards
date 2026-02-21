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
  const StartStudySession({required this.flashcards, this.randomize = false});
  @override
  List<Object?> get props => [flashcards, randomize];
}

class FlipCard extends StudyEvent {}

class NextCard extends StudyEvent {}

class PreviousCard extends StudyEvent {}

class RestartSession extends StudyEvent {
  final bool randomize;
  const RestartSession({this.randomize = false});
  @override
  List<Object?> get props => [randomize];
}
