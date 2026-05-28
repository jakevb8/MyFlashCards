import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeBonjourInTheCardList(WidgetTester tester) async {
  expect(find.text('Bonjour'), findsOneWidget);
}
