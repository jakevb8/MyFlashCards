import 'package:flutter_test/flutter_test.dart';

// Progress text "1 / 3" verifies all 3 cards are in the session
Future<void> all3CardsAppearInTheSession(WidgetTester tester) async {
  expect(find.textContaining('/ 3'), findsOneWidget);
}
