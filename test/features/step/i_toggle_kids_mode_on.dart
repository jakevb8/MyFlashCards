import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iToggleKidsModeOn(WidgetTester tester) async {
  await tester.tap(find.byType(Switch));
  await tester.pumpAndSettle();
}
