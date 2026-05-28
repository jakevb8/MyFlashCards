import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iTapTheShuffleIcon(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.shuffle));
  await tester.pumpAndSettle();
}
