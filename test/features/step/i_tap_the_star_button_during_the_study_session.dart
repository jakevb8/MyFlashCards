import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iTapTheStarButtonDuringTheStudySession(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.star_border).first);
  await tester.pumpAndSettle();
}
