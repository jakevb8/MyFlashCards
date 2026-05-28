import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveADeckNamedMaths(WidgetTester tester) async {
  resetTestState();
  testDeckRepo = FakeDeckRepository([makeDeck(name: 'Maths')]);
  await tester.pumpWidget(buildDeckListApp());
  await tester.pumpAndSettle();
}
