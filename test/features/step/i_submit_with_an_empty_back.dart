import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iSubmitWithAnEmptyBack(WidgetTester tester) async {
  // Fill front but leave back empty, then submit
  await tester.enterText(find.byType(TextFormField).first, 'Front text');
  await tester.tap(find.text('Add Card').last);
  await tester.pumpAndSettle();
}
