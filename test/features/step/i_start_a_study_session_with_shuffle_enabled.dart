import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/models/flashcard.dart';
import '../helpers/test_helpers.dart';

Future<void> iStartAStudySessionWithShuffleEnabled(WidgetTester tester) async {
  final deck = testCurrentDeck ?? makeDeck();
  final cards = testCurrentCards.isNotEmpty ? testCurrentCards : <Flashcard>[];
  await tester.pumpWidget(
    buildStudyApp(deck: deck, cards: cards, randomize: true),
  );
  await tester.pumpAndSettle();
}
