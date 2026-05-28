import 'package:flutter_test/flutter_test.dart';

// The study session sorts ascending by starCount, so the first card shown
// should have 0 stars (front text "Zero Stars") and the last should have 2.
Future<void> cardsWithMoreStarsShouldAppearLaterInTheSession(
  WidgetTester tester,
) async {
  expect(find.text('Zero Stars'), findsOneWidget);
  expect(find.text('One Star'), findsNothing);
  expect(find.text('Two Stars'), findsNothing);
}
