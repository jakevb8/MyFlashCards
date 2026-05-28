import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iTapTheSecondDeckToSelectIt(WidgetTester tester) async {
  await tester.tap(find.byType(ListTile).at(1));
  await tester.pumpAndSettle();
}
