import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iFilterByTheTagScience(WidgetTester tester) async {
  await tester.tap(
    find.byWidgetPredicate(
      (w) =>
          w is FilterChip &&
          w.label is Text &&
          (w.label as Text).data == 'science',
    ),
  );
  await tester.pumpAndSettle();
}
