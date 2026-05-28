import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveADeckWithCardsThatAreNotYetDue(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Study Deck');
  testCurrentDeck = deck;
  // nextReviewAt far in the future → not yet due
  final future = DateTime(2099, 1, 1);
  testCurrentCards = [
    makeCard(deckId: deck.id, front: 'Q1', back: 'A1', nextReviewAt: future),
    makeCard(deckId: deck.id, front: 'Q2', back: 'A2', nextReviewAt: future),
  ];
}
