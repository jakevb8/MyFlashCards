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

/// User rated a card after seeing its back. Triggers SM-2 scheduling and
/// persists the updated card, then advances to the next due card.
///
/// [quality] is the SM-2 quality value:
///   0 = Again, 2 = Hard, 3 = Good, 5 = Easy.
class RateCard extends StudyEvent {
  final String cardId;
  final int quality;
  const RateCard({required this.cardId, required this.quality});
  @override
  List<Object?> get props => [cardId, quality];
}
