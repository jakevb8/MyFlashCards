import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveADeckWithCardsWhereFrontIsCatAndBackIsGato(
  WidgetTester tester,
) async {
  resetTestState();
  final deck = makeDeck(name: 'Spanish');
  testCurrentDeck = deck;
  testCurrentCards = [makeCard(deckId: deck.id, front: 'cat', back: 'gato')];
}
