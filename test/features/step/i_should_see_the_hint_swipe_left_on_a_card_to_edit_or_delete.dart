import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeTheHintSwipeLeftOnACardToEditOrDelete(
  WidgetTester tester,
) async {
  expect(find.text('Swipe left on a card to edit or delete'), findsOneWidget);
}
