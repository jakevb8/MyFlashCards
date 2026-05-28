import 'package:flutter_test/flutter_test.dart';

Future<void> iSelectSystemBrightness(WidgetTester tester) async {
  await tester.tap(find.text('System'));
  await tester.pumpAndSettle();
}
