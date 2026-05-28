import 'package:flutter_test/flutter_test.dart';

Future<void> noGenerationRequestShouldBeMade(WidgetTester tester) async {
  markTestSkipped(
    'Requires Gemini API — not available in unit test environment',
  );
}
