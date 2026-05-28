import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveADeckNamedFrenchWordsWith3Cards(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'French Words');
  testCurrentDeck = deck;
  testDeckRepo = FakeDeckRepository([deck]);
  testCardRepo = FakeFlashcardRepository([
    makeCard(deckId: deck.id, front: 'Chat', back: 'Cat'),
    makeCard(deckId: deck.id, front: 'Chien', back: 'Dog'),
    makeCard(deckId: deck.id, front: 'Maison', back: 'House'),
  ]);
  await tester.pumpWidget(
    buildFlashcardListApp(deck: deck, cardRepo: testCardRepo),
  );
  await tester.pumpAndSettle();
}
