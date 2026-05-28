import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveTwoDecksEachWithDueCards(WidgetTester tester) async {
  resetTestState();
  final deckA = makeDeck(name: 'Deck Alpha');
  final deckB = makeDeck(name: 'Deck Beta');
  testDeckRepo = FakeDeckRepository([deckA, deckB]);
  testCardRepo = FakeFlashcardRepository([
    makeCard(deckId: deckA.id, front: 'A1', back: 'a1'),
    makeCard(deckId: deckA.id, front: 'A2', back: 'a2'),
    makeCard(deckId: deckB.id, front: 'B1', back: 'b1'),
    makeCard(deckId: deckB.id, front: 'B2', back: 'b2'),
  ]);
  await tester.pumpWidget(buildDeckListApp());
  await tester.pumpAndSettle();
}
