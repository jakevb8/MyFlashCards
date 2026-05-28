import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> aDeckContainsAnArchivedCard(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'My Deck');
  testCurrentDeck = deck;
  testCardRepo = FakeFlashcardRepository([
    makeCard(
      deckId: deck.id,
      front: 'Mastered Card',
      back: 'Answer',
      archived: true,
    ),
  ]);
  await tester.pumpWidget(
    buildFlashcardListApp(deck: deck, cardRepo: testCardRepo),
  );
  await tester.pumpAndSettle();
}
