import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iRenameItToAdvancedMaths(WidgetTester tester) async {
  await tester.drag(find.text('Maths'), const Offset(-500, 0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, 'Advanced Maths');
  await tester.tap(find.text('Save Changes'));
  await tester.pumpAndSettle();
}
