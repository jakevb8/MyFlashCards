import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theCardShouldBeReturnedToTheActiveListWith0Stars(
  WidgetTester tester,
) async {
  final cards = await testCardRepo.getFlashcards(testCurrentDeck!.id);
  final card = cards.firstWhere((c) => c.front == 'Mastered Card');
  expect(card.archived, isFalse);
  expect(card.starCount, equals(0));
}
