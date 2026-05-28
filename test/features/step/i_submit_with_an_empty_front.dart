import 'package:flutter_test/flutter_test.dart';

Future<void> iSubmitWithAnEmptyFront(WidgetTester tester) async {
  // Leave front empty, add some back text, then submit
  await tester.tap(find.text('Add Card').last);
  await tester.pumpAndSettle();
}
