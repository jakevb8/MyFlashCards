import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeGatoAsTheQuestionOnTheFirstCard(
  WidgetTester tester,
) async {
  expect(find.text('gato'), findsOneWidget);
}
