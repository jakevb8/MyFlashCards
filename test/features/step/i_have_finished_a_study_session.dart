import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/study/study_bloc.dart';
import 'package:my_flash_cards/blocs/study/study_event.dart';
import 'package:my_flash_cards/screens/study/study_screen.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveFinishedAStudySession(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Study Deck');
  testCurrentDeck = deck;
  testCurrentCards = [makeCard(deckId: deck.id, front: 'Q', back: 'A')];
  await tester.pumpWidget(buildStudyApp(deck: deck, cards: testCurrentCards));
  await tester.pumpAndSettle();
  final ctx = tester.element(
    find
        .descendant(
          of: find.byType(StudyScreen),
          matching: find.byType(Scaffold),
        )
        .first,
  );
  ctx.read<StudyBloc>().add(FlipCard());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Easy'));
  await tester.pumpAndSettle();
}
