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

/// Records that the user starred a card during this session.
/// Does NOT interact with storage — pair this with a [StarCard] event
/// dispatched to [FlashcardBloc].
class MarkStarredInSession extends StudyEvent {
  final String cardId;
  const MarkStarredInSession(this.cardId);
  @override
  List<Object?> get props => [cardId];
}
