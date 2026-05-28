import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iTapTheStarButtonOnThatCard(WidgetTester tester) async {
  // The star button in FlashcardListScreen is an IconButton with star_border icon
  await tester.tap(find.byIcon(Icons.star_border).first);
  await tester.pumpAndSettle();
}
