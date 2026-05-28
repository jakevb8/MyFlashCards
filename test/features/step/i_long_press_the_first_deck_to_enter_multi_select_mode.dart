import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iLongPressTheFirstDeckToEnterMultiSelectMode(
  WidgetTester tester,
) async {
  await tester.longPress(find.byType(ListTile).first);
  await tester.pumpAndSettle();
}
