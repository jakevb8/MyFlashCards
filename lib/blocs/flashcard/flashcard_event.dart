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
