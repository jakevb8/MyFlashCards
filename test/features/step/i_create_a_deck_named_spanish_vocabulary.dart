import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iCreateADeckNamedSpanishVocabulary(WidgetTester tester) async {
  await tester.tap(find.text('New Deck'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextFormField).first,
    'Spanish Vocabulary',
  );
  await tester.tap(find.text('Create Deck'));
  await tester.pumpAndSettle();
}
