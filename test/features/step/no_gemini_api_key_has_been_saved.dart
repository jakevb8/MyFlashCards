import 'package:flutter_test/flutter_test.dart';

Future<void> noGeminiApiKeyHasBeenSaved(WidgetTester tester) async {
  markTestSkipped(
    'Requires Gemini API — not available in unit test environment',
  );
}
