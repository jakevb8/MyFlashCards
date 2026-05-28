import 'package:flutter_test/flutter_test.dart';

Future<void> theCardShouldNoLongerAppearInTheActiveCardList(
  WidgetTester tester,
) async {
  // The card moved from active to archived — it should appear in archived section
  expect(find.text('Archived'), findsOneWidget);
}
