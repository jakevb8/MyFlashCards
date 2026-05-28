import 'package:flutter_test/flutter_test.dart';

Future<void> iSelectTheExecutiveTheme(WidgetTester tester) async {
  await tester.tap(find.text('Executive'));
  await tester.pumpAndSettle();
}
