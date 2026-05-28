import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> aDeckContainsACardWith2Stars(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'My Deck');
  testCurrentDeck = deck;
  testCardRepo = FakeFlashcardRepository([
    makeCard(deckId: deck.id, front: 'Star Card', back: 'Answer', starCount: 2),
  ]);
  await tester.pumpWidget(
    buildFlashcardListApp(deck: deck, cardRepo: testCardRepo),
  );
  await tester.pumpAndSettle();
}
