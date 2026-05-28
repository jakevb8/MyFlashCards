import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveADeckWith5Cards(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Big Deck');
  testCurrentDeck = deck;
  testCurrentCards = List.generate(
    5,
    (i) => makeCard(
      deckId: deck.id,
      front: 'Front ${i + 1}',
      back: 'Back ${i + 1}',
    ),
  );
}
