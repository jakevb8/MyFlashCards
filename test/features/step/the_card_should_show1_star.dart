import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> theCardShouldShow1Star(WidgetTester tester) async {
  // After starring once, one filled star icon should be visible
  expect(
    find.byIcon(Icons.star).evaluate().isNotEmpty ||
        find.text('★').evaluate().isNotEmpty,
    isTrue,
  );
}
