import 'package:flutter_test/flutter_test.dart';

Future<void> iSelectTheBubblegumTheme(WidgetTester tester) async {
  await tester.tap(find.text('Bubblegum'));
  await tester.pumpAndSettle();
}
