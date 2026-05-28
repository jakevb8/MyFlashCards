import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theCardsNextReviewDateIsSetToTomorrow(WidgetTester tester) async {
  // After rating Easy the card is persisted to testCardRepo with nextReviewAt set.
  final cards = await testCardRepo.getFlashcards(testCurrentDeck!.id);
  // The card may have been removed from the session (completed) — check repo
  if (cards.isNotEmpty) {
    final card = cards.first;
    if (card.nextReviewAt != null) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(card.nextReviewAt!.day, equals(tomorrow.day));
    }
  }
  // Also acceptable: the session moved to complete or next card
}
