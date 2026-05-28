import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldBeBackOnCard1(WidgetTester tester) async {
  // After restart the progress indicator shows "1 / N"
  expect(find.textContaining('1 /'), findsOneWidget);
}
