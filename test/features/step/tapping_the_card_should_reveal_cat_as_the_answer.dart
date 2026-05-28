import 'package:flutter_test/flutter_test.dart';

Future<void> tappingTheCardShouldRevealCatAsTheAnswer(
  WidgetTester tester,
) async {
  await tester.tap(find.text('gato'));
  await tester.pumpAndSettle();
  expect(find.text('cat'), findsOneWidget);
}
