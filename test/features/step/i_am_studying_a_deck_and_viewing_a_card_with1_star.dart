import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iAmStudyingADeckAndViewingACardWith1Star(
  WidgetTester tester,
) async {
  resetTestState();
  final deck = makeDeck(name: 'Study Deck');
  testCurrentDeck = deck;
  testCurrentCards = [
    makeCard(deckId: deck.id, front: 'Star Q', back: 'Star A', starCount: 1),
  ];
  testCardRepo = FakeFlashcardRepository(testCurrentCards);
  await tester.pumpWidget(
    buildStudyApp(deck: deck, cards: testCurrentCards, cardRepo: testCardRepo),
  );
  await tester.pumpAndSettle();
}
