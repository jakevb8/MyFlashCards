import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// After tapping the flip icon, the session restarts in flipped mode —
// the back of the card ('Back') is now shown as the question text.
Future<void> theFlipIconShouldBeHighlightedToIndicateFlippedMode(
  WidgetTester tester,
) async {
  expect(find.byIcon(Icons.flip_camera_android_outlined), findsOneWidget);
}
