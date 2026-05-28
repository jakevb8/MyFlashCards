import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeAStarButtonBelowTheNavigationButtons(
  WidgetTester tester,
) async {
  expect(
    find.byIcon(Icons.star_border).evaluate().isNotEmpty ||
        find.byIcon(Icons.star).evaluate().isNotEmpty,
    isTrue,
  );
}
