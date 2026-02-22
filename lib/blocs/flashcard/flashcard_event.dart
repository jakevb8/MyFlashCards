import 'package:equatable/equatable.dart';
import '../../models/flashcard.dart';

abstract class FlashcardEvent extends Equatable {
  const FlashcardEvent();
  @override
  List<Object?> get props => [];
}

class LoadFlashcards extends FlashcardEvent {
  final String deckId;
  const LoadFlashcards(this.deckId);
  @override
  List<Object?> get props => [deckId];
}

class AddFlashcard extends FlashcardEvent {
  final Flashcard flashcard;
  const AddFlashcard(this.flashcard);
  @override
  List<Object?> get props => [flashcard];
}

/// Saves a batch of flashcards atomically and reloads once.
/// Use this instead of firing multiple [AddFlashcard] events.
class AddFlashcards extends FlashcardEvent {
  final List<Flashcard> flashcards;
  const AddFlashcards(this.flashcards);
  @override
  List<Object?> get props => [flashcards];
}

class UpdateFlashcard extends FlashcardEvent {
  final Flashcard flashcard;
  const UpdateFlashcard(this.flashcard);
  @override
  List<Object?> get props => [flashcard];
}

class DeleteFlashcard extends FlashcardEvent {
  final String id;
  const DeleteFlashcard(this.id);
  @override
  List<Object?> get props => [id];
}

/// Increment star count on a card.
/// At 3 stars the card is automatically archived and stars reset to 0.
class StarCard extends FlashcardEvent {
  final String id;
  const StarCard(this.id);
  @override
  List<Object?> get props => [id];
}

/// Move an archived card back to the active list and reset its star count.
class UnarchiveCard extends FlashcardEvent {
  final String id;
  const UnarchiveCard(this.id);
  @override
  List<Object?> get props => [id];
}
