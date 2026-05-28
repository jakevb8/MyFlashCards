import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveACardWithFrontDeleteMeInTheDeck(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Test Deck');
  testCurrentDeck = deck;
  testCardRepo = FakeFlashcardRepository([
    makeCard(deckId: deck.id, front: 'Delete Me', back: 'Answer'),
  ]);
  await tester.pumpWidget(
    buildFlashcardListApp(deck: deck, cardRepo: testCardRepo),
  );
  await tester.pumpAndSettle();
}
