import 'package:flutter_test/flutter_test.dart';

/// Taps the 'Delete' action in whatever context is currently visible
/// (Slidable action pane for either deck or flashcard tiles).
Future<void> iTapDelete(WidgetTester tester) async {
  await tester.tap(find.text('Delete').first);
  await tester.pumpAndSettle();
}
