import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iConfirmTheDeletionInTheDialog(WidgetTester tester) async {
  // The confirmation dialog has a FilledButton(Delete) — tap it
  final deleteInDialog = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.text('Delete'),
  );
  await tester.tap(deleteInDialog);
  await tester.pumpAndSettle();
}
