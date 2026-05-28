import 'package:flutter_test/flutter_test.dart';

Future<void> iSelectTheRoseGardenTheme(WidgetTester tester) async {
  await tester.tap(find.text('Rose Garden'));
  await tester.pumpAndSettle();
}
