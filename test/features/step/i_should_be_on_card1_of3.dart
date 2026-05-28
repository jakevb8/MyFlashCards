import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldBeOnCard1Of3(WidgetTester tester) async {
  expect(find.text('1 / 3'), findsOneWidget);
}
