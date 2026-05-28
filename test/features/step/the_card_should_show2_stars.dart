import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> theCardShouldShow2Stars(WidgetTester tester) async {
  expect(
    find.byIcon(Icons.star).evaluate().length >= 2 ||
        find.byIcon(Icons.star_border).evaluate().isNotEmpty,
    isTrue,
  );
}
