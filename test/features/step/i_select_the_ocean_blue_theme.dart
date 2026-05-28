import 'package:flutter_test/flutter_test.dart';

Future<void> iSelectTheOceanBlueTheme(WidgetTester tester) async {
  await tester.tap(find.text('Ocean Blue'));
  await tester.pumpAndSettle();
}
