import 'package:flutter_test/flutter_test.dart';

Future<void> iSeeAYoureAllCaughtUpMessage(WidgetTester tester) async {
  expect(find.textContaining("You're all caught up"), findsOneWidget);
}
