import '../models/flashcard.dart';

abstract class FlashcardRepository {
  Future<List<Flashcard>> getFlashcards(String deckId);

  /// Returns all cards whose [Flashcard.deckId] is in [deckIds], sorted by
  /// createdAt. Used for bundled multi-deck study sessions.
  Future<List<Flashcard>> getFlashcardsByDecks(List<String> deckIds);

  Future<Flashcard> getFlashcard(String id);
  Future<void> addFlashcard(Flashcard flashcard);
  Future<void> updateFlashcard(Flashcard flashcard);
  Future<void> deleteFlashcard(String id);

  /// Returns the count of non-archived cards that are currently due for review.
  ///
  /// A card is due when [Flashcard.nextReviewAt] is null or not after now.
  Future<int> countDueCards();
}
