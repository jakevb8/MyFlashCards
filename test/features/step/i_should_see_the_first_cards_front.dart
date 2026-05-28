import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iShouldSeeTheFirstCardsFront(WidgetTester tester) async {
  final front = testCurrentCards.isNotEmpty
      ? testCurrentCards.first.front
      : 'Card 1';
  expect(find.text(front), findsOneWidget);
}
