import 'package:flutter_test/flutter_test.dart';

Future<void> thePreviewShouldContainExactly20Cards(WidgetTester tester) async {
  markTestSkipped(
    'Requires Gemini API — not available in unit test environment',
  );
}
