import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveADeckNamedFrenchWords(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'French Words');
  testCurrentDeck = deck;
  testCardRepo = FakeFlashcardRepository();
  await tester.pumpWidget(
    buildFlashcardListApp(deck: deck, cardRepo: testCardRepo),
  );
  await tester.pumpAndSettle();
}
