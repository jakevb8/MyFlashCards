import 'package:flutter_test/flutter_test.dart';

Future<void> theAccountSectionShouldNoLongerBeVisible(
  WidgetTester tester,
) async {
  markTestSkipped(
    'Requires Firebase Auth — not available in unit test environment',
  );
}
