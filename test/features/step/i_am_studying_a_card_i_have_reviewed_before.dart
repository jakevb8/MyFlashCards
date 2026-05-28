import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iAmStudyingACardIHaveReviewedBefore(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Study Deck');
  testCurrentDeck = deck;
  // A card with previous SM-2 data: 3 repetitions, 3-day interval
  testCurrentCards = [
    makeCard(
      deckId: deck.id,
      front: 'Old Q',
      back: 'Old A',
      repetitions: 3,
      intervalDays: 3,
      easeFactor: 2.5,
    ),
  ];
  await tester.pumpWidget(buildStudyApp(deck: deck, cards: testCurrentCards));
  await tester.pumpAndSettle();
}
