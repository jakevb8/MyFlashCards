import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldOnlySeeTheScienceDeck(WidgetTester tester) async {
  expect(find.text('Science Deck'), findsOneWidget);
  expect(find.text('History Deck'), findsNothing);
}
