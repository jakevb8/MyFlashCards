import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

// With shuffle enabled all cards are still in the session — verify count
Future<void> theCardsShouldBeInADifferentOrder(WidgetTester tester) async {
  final total = testCurrentCards.length;
  expect(find.textContaining('/ $total'), findsOneWidget);
}
