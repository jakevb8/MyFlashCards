import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iStartAStudySession(WidgetTester tester) async {
  final deck = testCurrentDeck ?? makeDeck();
  final cards = testCurrentCards;
  await tester.pumpWidget(buildStudyApp(deck: deck, cards: cards));
  await tester.pumpAndSettle();
}
