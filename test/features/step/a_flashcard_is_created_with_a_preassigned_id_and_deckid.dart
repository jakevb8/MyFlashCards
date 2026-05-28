import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> aFlashcardIsCreatedWithAPreassignedIdAndDeckid(
  WidgetTester tester,
) async {
  resetTestState();
  const cardId = 'preset-card-id-xyz789';
  const deckId = 'preset-deck-id-for-card';
  testExpectedCardId = cardId;
  testExpectedCardDeckId = deckId;
  await testCardRepo.addFlashcard(
    makeCard(id: cardId, deckId: deckId, front: 'Q', back: 'A'),
  );
}
