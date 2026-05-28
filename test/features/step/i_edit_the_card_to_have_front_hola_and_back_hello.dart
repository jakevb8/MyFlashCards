import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iEditTheCardToHaveFrontHolaAndBackHello(
  WidgetTester tester,
) async {
  // Swipe left on the card tile to reveal Edit/Delete actions
  await tester.drag(find.text('Hola'), const Offset(-500, 0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit'));
  await tester.pumpAndSettle();
  // Update the back field (keep front as 'Hola', change back to 'Hello')
  await tester.enterText(find.byType(TextFormField).last, 'Hello');
  await tester.tap(find.text('Save Changes'));
  await tester.pumpAndSettle();
}
