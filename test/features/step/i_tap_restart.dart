import 'package:flutter_test/flutter_test.dart';

Future<void> iTapRestart(WidgetTester tester) async {
  await tester.tap(find.text('Restart'));
  await tester.pumpAndSettle();
}
