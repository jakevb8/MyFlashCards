import 'package:flutter_test/flutter_test.dart';

Future<void> theArchivedCardShouldNotAppear(WidgetTester tester) async {
  expect(find.text('Archived Card'), findsNothing);
}
