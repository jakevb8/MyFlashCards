import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> theStarButtonShouldUpdateImmediately(WidgetTester tester) async {
  // After starring, the button shows a filled star (already starred this session)
  expect(find.byIcon(Icons.star).evaluate().isNotEmpty, isTrue);
}
