import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeSpanishVocabularyInMyDeckList(
  WidgetTester tester,
) async {
  expect(find.text('Spanish Vocabulary'), findsOneWidget);
}
