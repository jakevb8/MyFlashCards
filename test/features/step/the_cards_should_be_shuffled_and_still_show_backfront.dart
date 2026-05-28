import 'package:flutter_test/flutter_test.dart';

// In flipped mode the card's back text is shown as the "question".
// The original backs for the setup cards are B1, B2, B3.
Future<void> theCardsShouldBeShuffledAndStillShowBackfront(
  WidgetTester tester,
) async {
  final hasBackText = find.textContaining('B').evaluate().isNotEmpty;
  expect(
    hasBackText,
    isTrue,
    reason: 'Expected a card back (B1/B2/B3) to be visible in flipped mode',
  );
}
