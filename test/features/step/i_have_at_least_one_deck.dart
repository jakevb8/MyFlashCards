import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveAtLeastOneDeck(WidgetTester tester) async {
  resetTestState();
  testDeckRepo = FakeDeckRepository([makeDeck(name: 'My Deck')]);
  await tester.pumpWidget(buildDeckListApp());
  await tester.pumpAndSettle();
}
