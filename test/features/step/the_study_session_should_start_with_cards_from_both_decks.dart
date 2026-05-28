import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/screens/study/study_screen.dart';

Future<void> theStudySessionShouldStartWithCardsFromBothDecks(
  WidgetTester tester,
) async {
  expect(find.byType(StudyScreen), findsOneWidget);
  // Combined title shows both deck names joined with " + ".
  expect(find.text('Deck Alpha + Deck Beta'), findsOneWidget);
}
