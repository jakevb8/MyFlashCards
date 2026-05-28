import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

/// Confirms that neither the deck ID nor the card ID was overwritten by a
/// freshly-generated UUID. Both IDs must still match the pre-assigned values.
Future<void> itShouldNotBeReplacedWithANewUuid(WidgetTester tester) async {
  if (testExpectedDeckId != null) {
    final decks = await testDeckRepo.getDecks();
    expect(decks.any((d) => d.id == testExpectedDeckId), isTrue);
  }
  if (testExpectedCardId != null) {
    final cards = await testCardRepo.getFlashcards(
      testExpectedCardDeckId ?? '',
    );
    expect(cards.any((c) => c.id == testExpectedCardId), isTrue);
  }
}
