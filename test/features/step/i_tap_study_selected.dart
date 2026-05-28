import 'package:flutter_test/flutter_test.dart';

Future<void> iTapStudySelected(WidgetTester tester) async {
  await tester.tap(find.text('Study Selected'));
  await tester.pumpAndSettle();
  // Dismiss the StudyModePickerSheet with Start Session.
  await tester.tap(find.text('Start Session'));
  await tester.pumpAndSettle();
}
