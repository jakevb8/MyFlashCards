import 'package:flutter_test/flutter_test.dart';

Future<void> iSelectDarkBrightness(WidgetTester tester) async {
  await tester.tap(find.text('Dark'));
  await tester.pumpAndSettle();
}
