import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveADeckWith3Cards(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'My Deck');
  testCurrentDeck = deck;
  testCurrentCards = [
    makeCard(deckId: deck.id, front: 'Card 1', back: 'Answer 1'),
    makeCard(deckId: deck.id, front: 'Card 2', back: 'Answer 2'),
    makeCard(deckId: deck.id, front: 'Card 3', back: 'Answer 3'),
  ];
}
