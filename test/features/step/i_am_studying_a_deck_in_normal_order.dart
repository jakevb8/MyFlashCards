import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iAmStudyingADeckInNormalOrder(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Deck');
  testCurrentDeck = deck;
  testCurrentCards = [makeCard(deckId: deck.id, front: 'Front', back: 'Back')];
  await tester.pumpWidget(
    buildStudyApp(deck: deck, cards: testCurrentCards, flipped: false),
  );
  await tester.pumpAndSettle();
}
