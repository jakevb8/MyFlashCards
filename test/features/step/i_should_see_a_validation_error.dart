import 'package:flutter_test/flutter_test.dart';

/// Checks that at least one form validation error is visible.
/// Works for both deck forms ('Name is required') and flashcard forms
/// ('Front is required', 'Back is required').
Future<void> iShouldSeeAValidationError(WidgetTester tester) async {
  final hasError = find.textContaining('required').evaluate().isNotEmpty;
  expect(hasError, isTrue, reason: 'Expected a validation error to be visible');
}
