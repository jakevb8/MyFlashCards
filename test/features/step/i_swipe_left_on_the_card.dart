import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iSwipeLeftOnTheCard(WidgetTester tester) async {
  // Flashcard items are Card widgets inside Slidable; swipe one left to reveal actions.
  final cardWidget = find.byType(Card).first;
  await tester.drag(cardWidget, const Offset(-500, 0));
  await tester.pumpAndSettle();
}
