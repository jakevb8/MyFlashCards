import 'package:flutter_test/flutter_test.dart';

Future<void> iSelectLightBrightness(WidgetTester tester) async {
  await tester.tap(find.text('Light'));
  await tester.pumpAndSettle();
}
