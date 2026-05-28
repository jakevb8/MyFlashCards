import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theDeckStoredInTheRepositoryShouldHaveThatSameId(
  WidgetTester tester,
) async {
  final decks = await testDeckRepo.getDecks();
  expect(decks, isNotEmpty);
  expect(decks.first.id, equals(testExpectedDeckId));
}
