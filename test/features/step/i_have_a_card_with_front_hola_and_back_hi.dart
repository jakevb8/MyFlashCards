import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveACardWithFrontHolaAndBackHi(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Vocabulary');
  testCurrentDeck = deck;
  testCardRepo = FakeFlashcardRepository([
    makeCard(deckId: deck.id, front: 'Hola', back: 'Hi'),
  ]);
  await tester.pumpWidget(
    buildFlashcardListApp(deck: deck, cardRepo: testCardRepo),
  );
  await tester.pumpAndSettle();
}
