import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iStartAStudySessionInOrder(WidgetTester tester) async {
  final deck = testCurrentDeck ?? makeDeck();
  final cards = testCurrentCards.isNotEmpty
      ? testCurrentCards
      : [makeCard(deckId: deck.id, front: 'Q', back: 'A')];
  await tester.pumpWidget(buildStudyApp(deck: deck, cards: cards));
  await tester.pumpAndSettle();
}
