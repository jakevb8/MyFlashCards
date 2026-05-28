import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldNotSeeMathsInMyDeckList(WidgetTester tester) async {
  expect(find.text('Maths'), findsNothing);
}
