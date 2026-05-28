import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveADeckTaggedScienceAndADeckTaggedHistory(
  WidgetTester tester,
) async {
  resetTestState();
  testDeckRepo = FakeDeckRepository([
    makeDeck(name: 'Science Deck', tags: ['science']),
    makeDeck(name: 'History Deck', tags: ['history']),
  ]);
  await tester.pumpWidget(buildDeckListApp());
  await tester.pumpAndSettle();
}
