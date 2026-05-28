import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theAppHasJustLaunched(WidgetTester tester) async {
  resetTestState();
  await tester.pumpWidget(buildDeckListApp());
  await tester.pumpAndSettle();
}
