import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldNotSeeDeleteMeInTheCardList(WidgetTester tester) async {
  expect(find.text('Delete Me'), findsNothing);
}
