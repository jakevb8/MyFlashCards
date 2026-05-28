import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveADeckNamedOldDeck(WidgetTester tester) async {
  resetTestState();
  testDeckRepo = FakeDeckRepository([makeDeck(name: 'Old Deck')]);
  await tester.pumpWidget(buildDeckListApp());
  await tester.pumpAndSettle();
}
