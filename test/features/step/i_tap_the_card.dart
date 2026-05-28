import 'package:flutter_test/flutter_test.dart';

Future<void> iTapTheCard(WidgetTester tester) async {
  // Tap the GestureDetector wrapping the card face to flip it
  await tester.tap(find.text('Front Text'));
  await tester.pumpAndSettle();
}
