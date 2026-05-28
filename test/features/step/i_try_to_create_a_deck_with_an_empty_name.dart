import 'package:flutter_test/flutter_test.dart';

Future<void> iTryToCreateADeckWithAnEmptyName(WidgetTester tester) async {
  await tester.tap(find.text('New Deck'));
  await tester.pumpAndSettle();
  // Leave the name field empty and attempt to submit
  await tester.tap(find.text('Create Deck'));
  await tester.pumpAndSettle();
}
