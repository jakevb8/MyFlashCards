import 'package:flutter_test/flutter_test.dart';

Future<void> theCardShouldAppearInTheArchivedSection(
  WidgetTester tester,
) async {
  expect(find.text('Archived'), findsOneWidget);
  expect(find.text('Star Card'), findsOneWidget);
}
