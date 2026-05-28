import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/screens/cards/flashcard_list_screen.dart';

/// No-op if already on FlashcardListScreen.
Future<void> iAmOnTheCardListScreen(WidgetTester tester) async {
  expect(find.byType(FlashcardListScreen), findsOneWidget);
}
