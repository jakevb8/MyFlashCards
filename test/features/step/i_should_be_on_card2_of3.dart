import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldBeOnCard2Of3(WidgetTester tester) async {
  expect(find.text('2 / 3'), findsOneWidget);
}
