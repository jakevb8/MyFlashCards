import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> aDeckContainsCardsWithStarCounts01And2(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'My Deck');
  testCurrentDeck = deck;
  testCurrentCards = [
    makeCard(deckId: deck.id, front: 'Zero Stars', back: 'A', starCount: 0),
    makeCard(deckId: deck.id, front: 'One Star', back: 'B', starCount: 1),
    makeCard(deckId: deck.id, front: 'Two Stars', back: 'C', starCount: 2),
  ];
}
