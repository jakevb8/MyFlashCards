import 'package:equatable/equatable.dart';
import '../../models/flashcard.dart';
import '../../models/study_mode.dart';

abstract class StudyEvent extends Equatable {
  const StudyEvent();
  @override
  List<Object?> get props => [];
}

/// Begins a new study session with the given cards.
///
/// [mode] controls how each card is presented. Defaults to [StudyMode.flashcard]
/// so that all existing call sites continue to work without changes.
/// [tolerantMatching] only affects [StudyMode.typeAnswer]: when true, answers
/// within an edit-distance of 2 are also accepted as correct.
class StartStudySession extends StudyEvent {
  final List<Flashcard> flashcards;
  final bool randomize;
  final bool flipped;
  final StudyMode mode;
  final bool tolerantMatching;

  const StartStudySession({
    required this.flashcards,
    this.randomize = false,
    this.flipped = false,
    this.mode = StudyMode.flashcard,
    this.tolerantMatching = false,
  });

  @override
  List<Object?> get props => [
    flashcards,
    randomize,
    flipped,
    mode,
    tolerantMatching,
  ];
}

class FlipCard extends StudyEvent {}

class NextCard extends StudyEvent {}

class PreviousCard extends StudyEvent {}

/// Restarts the session with the same mode and tolerance as the current session.
/// [flipped] and [randomize] can be changed per-restart (e.g. shuffle button).
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
/// For non-flashcard modes the quality is set automatically by the view:
///   multipleChoice correct → 5, wrong → 0
///   typeAnswer correct → 4, wrong → 0
class RateCard extends StudyEvent {
  final String cardId;
  final int quality;
  const RateCard({required this.cardId, required this.quality});
  @override
  List<Object?> get props => [cardId, quality];
}

/// User edited the current card's text during an active session.
///
/// [updated] must be in **canonical** (non-flipped) orientation — i.e. the
/// real front/back values, not the swapped display values used in flipped mode.
/// StudyBloc re-applies the flip transform when updating the session card list.
class EditCardInSession extends StudyEvent {
  final Flashcard updated;
  const EditCardInSession(this.updated);
  @override
  List<Object?> get props => [updated];
}
