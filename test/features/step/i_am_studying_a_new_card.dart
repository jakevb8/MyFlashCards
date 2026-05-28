import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iAmStudyingANewCard(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Study Deck');
  testCurrentDeck = deck;
  // New card: no nextReviewAt, no SM-2 fields
  testCurrentCards = [makeCard(deckId: deck.id, front: 'New Q', back: 'New A')];
  await tester.pumpWidget(buildStudyApp(deck: deck, cards: testCurrentCards));
  await tester.pumpAndSettle();
}
