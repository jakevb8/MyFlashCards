import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theDeckShouldRestartWithBackShownFirst(WidgetTester tester) async {
  // When flipped, the 'back' text should be visible as the question
  expect(find.text(testCurrentCards.first.back), findsOneWidget);
}
