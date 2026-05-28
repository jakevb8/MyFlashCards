import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeTheHintSwipeLeftOnADeckToEditOrDelete(
  WidgetTester tester,
) async {
  expect(find.text('Swipe left on a deck to edit or delete'), findsOneWidget);
}
