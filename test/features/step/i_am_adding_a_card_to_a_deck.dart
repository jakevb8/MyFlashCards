import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iAmAddingACardToADeck(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Test Deck');
  testCurrentDeck = deck;
  testCardRepo = FakeFlashcardRepository();
  await tester.pumpWidget(
    buildFlashcardListApp(deck: deck, cardRepo: testCardRepo),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add Card'));
  await tester.pumpAndSettle();
}
