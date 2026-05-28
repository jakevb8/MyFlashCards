import 'package:flutter_test/flutter_test.dart';

Future<void> iTapPrivacyPolicy(WidgetTester tester) async {
  markTestSkipped(
    'Requires Firebase Auth — not available in unit test environment',
  );
}
