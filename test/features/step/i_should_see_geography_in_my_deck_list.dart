import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeGeographyInMyDeckList(WidgetTester tester) async {
  expect(find.text('Geography'), findsOneWidget);
}
