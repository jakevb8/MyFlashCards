import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/study/study_bloc.dart';
import 'package:my_flash_cards/blocs/study/study_event.dart';
import 'package:my_flash_cards/screens/study/study_screen.dart';
import '../helpers/test_helpers.dart';

Future<void> iAmOnCard2Of3InAStudySession(WidgetTester tester) async {
  resetTestState();
  final deck = makeDeck(name: 'Study Deck');
  testCurrentDeck = deck;
  testCurrentCards = [
    makeCard(deckId: deck.id, front: 'A1', back: 'B1'),
    makeCard(deckId: deck.id, front: 'A2', back: 'B2'),
    makeCard(deckId: deck.id, front: 'A3', back: 'B3'),
  ];
  await tester.pumpWidget(buildStudyApp(deck: deck, cards: testCurrentCards));
  await tester.pumpAndSettle();
  // Advance to card 2 using the Scaffold context (inside BlocProvider).
  final ctx = tester.element(
    find
        .descendant(
          of: find.byType(StudyScreen),
          matching: find.byType(Scaffold),
        )
        .first,
  );
  ctx.read<StudyBloc>().add(NextCard());
  await tester.pumpAndSettle();
  expect(find.textContaining('2 /'), findsOneWidget);
}
