import 'package:flutter_test/flutter_test.dart';

Future<void> iSeeATapCardToFlipHintAndNoRatingButtons(
  WidgetTester tester,
) async {
  expect(find.text('Tap card to flip'), findsOneWidget);
  // Rating buttons are only shown after flipping
  expect(find.text('Easy'), findsNothing);
  expect(find.text('Again'), findsNothing);
}
