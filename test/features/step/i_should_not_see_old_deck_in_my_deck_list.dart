import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldNotSeeOldDeckInMyDeckList(WidgetTester tester) async {
  expect(find.text('Old Deck'), findsNothing);
}
