import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iAmOnCard1Of3InAStudySession(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Study Deck');
  testCurrentDeck = deck;
  testCurrentCards = [
    makeCard(deckId: deck.id, front: 'A1', back: 'B1'),
    makeCard(deckId: deck.id, front: 'A2', back: 'B2'),
    makeCard(deckId: deck.id, front: 'A3', back: 'B3'),
  ];
  await tester.pumpWidget(buildStudyApp(deck: deck, cards: testCurrentCards));
  await tester.pumpAndSettle();
  // Ensure we're on card 1
  expect(find.text('1 / 3'), findsOneWidget);
}
