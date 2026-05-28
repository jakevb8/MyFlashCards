import '../models/flashcard.dart';

abstract class FlashcardRepository {
  Future<List<Flashcard>> getFlashcards(String deckId);
  Future<Flashcard> getFlashcard(String id);
  Future<void> addFlashcard(Flashcard flashcard);
  Future<void> updateFlashcard(Flashcard flashcard);
  Future<void> deleteFlashcard(String id);

  /// Returns the count of non-archived cards that are currently due for review.
  ///
  /// A card is due when [Flashcard.nextReviewAt] is null or not after now.
  Future<int> countDueCards();
}
