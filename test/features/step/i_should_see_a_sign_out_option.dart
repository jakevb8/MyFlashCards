import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeASignOutOption(WidgetTester tester) async {
  markTestSkipped(
    'Requires Firebase Auth — not available in unit test environment',
  );
}
