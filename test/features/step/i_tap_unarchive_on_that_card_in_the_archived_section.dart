import 'package:flutter_test/flutter_test.dart';

Future<void> iTapUnarchiveOnThatCardInTheArchivedSection(
  WidgetTester tester,
) async {
  // Swipe left on the archived card to reveal Unarchive action
  await tester.drag(find.text('Mastered Card'), const Offset(-500, 0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Unarchive'));
  await tester.pumpAndSettle();
}
