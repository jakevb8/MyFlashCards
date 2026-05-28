import 'package:flutter_test/flutter_test.dart';

Future<void> iAdvanceToTheNextCardAutomatically(WidgetTester tester) async {
  // After rating, the session either shows the next card or the completion screen
  await tester.pumpAndSettle();
  final onComplete = find.text('Session Complete!').evaluate().isNotEmpty;
  final onNext = find.textContaining(' / ').evaluate().isNotEmpty;
  expect(onComplete || onNext, isTrue);
}
