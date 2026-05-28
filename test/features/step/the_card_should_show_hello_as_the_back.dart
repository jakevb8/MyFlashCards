import 'package:flutter_test/flutter_test.dart';

Future<void> theCardShouldShowHelloAsTheBack(WidgetTester tester) async {
  expect(find.text('Hello'), findsOneWidget);
}
