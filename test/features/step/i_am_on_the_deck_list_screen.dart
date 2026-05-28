import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/screens/decks/deck_list_screen.dart';
import '../helpers/test_helpers.dart';

/// If a widget hasn't been pumped yet, pump the deck list now.
/// Otherwise the deck list is already on screen.
Future<void> iAmOnTheDeckListScreen(WidgetTester tester) async {
  if (find.byType(DeckListScreen).evaluate().isEmpty) {
    resetTestState();
    await tester.pumpWidget(buildDeckListApp());
    await tester.pumpAndSettle();
  }
}
