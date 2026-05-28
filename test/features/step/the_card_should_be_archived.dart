import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theCardShouldBeArchived(WidgetTester tester) async {
  final cards = await testCardRepo.getFlashcards(testCurrentDeck!.id);
  expect(cards.any((c) => c.archived), isTrue);
}
