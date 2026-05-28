import 'package:flutter_test/flutter_test.dart';

// Progress text is shown as "1 / N" in the AppBar; assert N == 3
Future<void> theSessionShouldContain3Cards(WidgetTester tester) async {
  expect(find.textContaining('/ 3'), findsOneWidget);
}
