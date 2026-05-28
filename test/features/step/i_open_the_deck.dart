import 'package:flutter_test/flutter_test.dart';

/// The deck list screen is already showing; tapping a deck tile opens it.
/// In tests that use buildFlashcardListApp, the screen is already open so
/// this is a no-op.
Future<void> iOpenTheDeck(WidgetTester tester) async {
  // FlashcardListScreen is already the home; nothing to do.
  await tester.pumpAndSettle();
}
