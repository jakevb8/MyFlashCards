import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Swipes left on the first deck tile to reveal the Slidable actions.
Future<void> iSwipeLeftOnTheDeck(WidgetTester tester) async {
  // Drag the deck tile far left to open the end action pane
  final deckTile = find.byType(ListTile).first;
  await tester.drag(deckTile, const Offset(-500, 0));
  await tester.pumpAndSettle();
}
