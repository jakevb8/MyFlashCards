import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theFlashcardStoredInTheRepositoryShouldHaveThatSameIdAndDeckid(
  WidgetTester tester,
) async {
  final cards = await testCardRepo.getFlashcards(testExpectedCardDeckId ?? '');
  expect(cards, isNotEmpty);
  expect(cards.first.id, equals(testExpectedCardId));
  expect(cards.first.deckId, equals(testExpectedCardDeckId));
}
