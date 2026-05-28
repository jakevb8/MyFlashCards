import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iAmStudyingAFlippedDeck(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Deck');
  testCurrentDeck = deck;
  testCurrentCards = [
    makeCard(deckId: deck.id, front: 'F1', back: 'B1'),
    makeCard(deckId: deck.id, front: 'F2', back: 'B2'),
    makeCard(deckId: deck.id, front: 'F3', back: 'B3'),
  ];
  await tester.pumpWidget(
    buildStudyApp(deck: deck, cards: testCurrentCards, flipped: true),
  );
  await tester.pumpAndSettle();
}
