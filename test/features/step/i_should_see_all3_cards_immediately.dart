import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeAll3CardsImmediately(WidgetTester tester) async {
  // The card list should show all 3 cards without any extra interaction
  expect(find.text('Chat'), findsOneWidget);
  expect(find.text('Chien'), findsOneWidget);
  expect(find.text('Maison'), findsOneWidget);
}
