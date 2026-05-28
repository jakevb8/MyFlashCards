import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> aDeckContains3ActiveCardsAnd1ArchivedCard(
  WidgetTester tester,
) async {
  resetTestState();
  final deck = makeDeck(name: 'My Deck');
  testCurrentDeck = deck;
  testCurrentCards = [
    makeCard(deckId: deck.id, front: 'Active 1', back: 'A1'),
    makeCard(deckId: deck.id, front: 'Active 2', back: 'A2'),
    makeCard(deckId: deck.id, front: 'Active 3', back: 'A3'),
    makeCard(
      deckId: deck.id,
      front: 'Archived Card',
      back: 'AA',
      archived: true,
    ),
  ];
  testCardRepo = FakeFlashcardRepository(testCurrentCards);
}
