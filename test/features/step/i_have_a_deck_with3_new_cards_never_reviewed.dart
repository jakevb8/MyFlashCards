import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveADeckWith3NewCardsNeverReviewed(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Study Deck');
  testCurrentDeck = deck;
  // nextReviewAt == null → card is brand new, always shown
  testCurrentCards = [
    makeCard(deckId: deck.id, front: 'Q1', back: 'A1'),
    makeCard(deckId: deck.id, front: 'Q2', back: 'A2'),
    makeCard(deckId: deck.id, front: 'Q3', back: 'A3'),
  ];
}
