import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theCardsStarCountShouldIncrementTo2(WidgetTester tester) async {
  final cards = await testCardRepo.getFlashcards(testCurrentDeck!.id);
  if (cards.isNotEmpty) {
    expect(cards.first.starCount, equals(2));
  }
}
