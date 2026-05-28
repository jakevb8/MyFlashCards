import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iAmStudyingACardShowingTheFront(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Study Deck');
  testCurrentDeck = deck;
  testCurrentCards = [
    makeCard(deckId: deck.id, front: 'Front Text', back: 'Back Text'),
  ];
  await tester.pumpWidget(buildStudyApp(deck: deck, cards: testCurrentCards));
  await tester.pumpAndSettle();
}
