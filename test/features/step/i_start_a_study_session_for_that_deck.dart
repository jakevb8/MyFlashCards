import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iStartAStudySessionForThatDeck(WidgetTester tester) async {
  final deck = testCurrentDeck ?? makeDeck();
  // Exclude archived cards (mimics FlashcardListScreen._pickModeAndStudy)
  final studyCards = testCurrentCards.where((c) => !c.archived).toList();
  await tester.pumpWidget(
    buildStudyApp(deck: deck, cards: studyCards, cardRepo: testCardRepo),
  );
  await tester.pumpAndSettle();
}
