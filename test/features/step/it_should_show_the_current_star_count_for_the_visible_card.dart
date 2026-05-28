import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> itShouldShowTheCurrentStarCountForTheVisibleCard(
  WidgetTester tester,
) async {
  // The star button tooltip shows the current star count
  final card = testCurrentCards.first;
  expect(
    find
            .byTooltip(
              'I know this card! (${card.starCount}/3 — at 3 it\'s archived)',
            )
            .evaluate()
            .isNotEmpty ||
        find
            .byTooltip('Already starred this card (${card.starCount}/3)')
            .evaluate()
            .isNotEmpty,
    isTrue,
  );
}
