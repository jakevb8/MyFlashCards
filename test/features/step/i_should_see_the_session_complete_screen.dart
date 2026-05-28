import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeTheSessionCompleteScreen(WidgetTester tester) async {
  expect(find.text('Session Complete!'), findsOneWidget);
}
