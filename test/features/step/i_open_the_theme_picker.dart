import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iOpenTheThemePicker(WidgetTester tester) async {
  // Increase viewport so the theme picker sheet doesn't overflow in tests.
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  await tester.tap(find.byIcon(Icons.palette_outlined));
  await tester.pumpAndSettle();
}
