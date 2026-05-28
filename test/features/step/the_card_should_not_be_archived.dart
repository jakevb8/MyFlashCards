import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theCardShouldNotBeArchived(WidgetTester tester) async {
  final cards = await testCardRepo.getFlashcards(testCurrentDeck!.id);
  // Non-archived cards appear in the active list; archived section label wouldn't show
  final archived = cards.where((c) => c.archived).toList();
  expect(archived, isEmpty);
}
