import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iAddACardWithFrontBonjourAndBackHello(WidgetTester tester) async {
  await tester.tap(find.text('Add Card'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, 'Bonjour');
  await tester.enterText(find.byType(TextFormField).last, 'Hello');
  await tester.tap(find.text('Add Card').last);
  await tester.pumpAndSettle();
}
