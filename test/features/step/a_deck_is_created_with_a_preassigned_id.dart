import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> aDeckIsCreatedWithAPreassignedId(WidgetTester tester) async {
  resetTestState();
  const id = 'preset-deck-id-abc123';
  testExpectedDeckId = id;
  await testDeckRepo.addDeck(makeDeck(id: id, name: 'Pre-ID Deck'));
}
