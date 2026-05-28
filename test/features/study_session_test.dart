// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/i_have_a_deck_with3_cards.dart';
import './step/i_start_a_study_session_in_order.dart';
import './step/i_should_see_the_first_cards_front.dart';
import './step/i_am_studying_a_card_showing_the_front.dart';
import './step/i_tap_the_card.dart';
import './step/i_should_see_the_cards_back.dart';
import './step/i_am_on_card1_of3_in_a_study_session.dart';
import './step/i_tap_next.dart';
import './step/i_should_be_on_card2_of3.dart';
import './step/i_am_on_card2_of3_in_a_study_session.dart';
import './step/i_tap_previous.dart';
import './step/i_should_be_on_card1_of3.dart';
import './step/i_am_on_the_last_card_in_a_study_session.dart';
import './step/i_tap_finish.dart';
import './step/i_should_see_the_session_complete_screen.dart';
import './step/i_have_a_deck_with5_cards.dart';
import './step/i_start_a_study_session_with_shuffle_enabled.dart';
import './step/the_cards_should_be_in_a_different_order.dart';
import './step/i_have_finished_a_study_session.dart';
import './step/i_tap_restart.dart';
import './step/i_should_be_back_on_card1.dart';
import './step/i_have_a_deck_with_cards_where_front_is_cat_and_back_is_gato.dart';
import './step/i_start_a_study_session_with_study_flipped.dart';
import './step/i_should_see_gato_as_the_question_on_the_first_card.dart';
import './step/tapping_the_card_should_reveal_cat_as_the_answer.dart';
import './step/i_am_studying_a_deck_in_normal_order.dart';
import './step/i_tap_the_flip_icon_in_the_app_bar.dart';
import './step/the_deck_should_restart_with_back_shown_first.dart';
import './step/the_flip_icon_should_be_highlighted_to_indicate_flipped_mode.dart';
import './step/i_am_studying_a_flipped_deck.dart';
import './step/i_tap_the_shuffle_icon.dart';
import './step/the_cards_should_be_shuffled_and_still_show_backfront.dart';

void main() {
  group('''Study Session''', () {
    testWidgets('''Study cards in order''', (tester) async {
      await iHaveADeckWith3Cards(tester);
      await iStartAStudySessionInOrder(tester);
      await iShouldSeeTheFirstCardsFront(tester);
    });
    testWidgets('''Flip a card''', (tester) async {
      await iAmStudyingACardShowingTheFront(tester);
      await iTapTheCard(tester);
      await iShouldSeeTheCardsBack(tester);
    });
    testWidgets('''Navigate to next card''', (tester) async {
      await iAmOnCard1Of3InAStudySession(tester);
      await iTapNext(tester);
      await iShouldBeOnCard2Of3(tester);
    });
    testWidgets('''Navigate to previous card''', (tester) async {
      await iAmOnCard2Of3InAStudySession(tester);
      await iTapPrevious(tester);
      await iShouldBeOnCard1Of3(tester);
    });
    testWidgets('''Complete a session''', (tester) async {
      await iAmOnTheLastCardInAStudySession(tester);
      await iTapFinish(tester);
      await iShouldSeeTheSessionCompleteScreen(tester);
    });
    testWidgets('''Shuffle cards''', (tester) async {
      await iHaveADeckWith5Cards(tester);
      await iStartAStudySessionWithShuffleEnabled(tester);
      await theCardsShouldBeInADifferentOrder(tester);
    });
    testWidgets('''Restart a session''', (tester) async {
      await iHaveFinishedAStudySession(tester);
      await iTapRestart(tester);
      await iShouldBeBackOnCard1(tester);
    });
    testWidgets('''Study with deck flipped (back shown first)''', (
      tester,
    ) async {
      await iHaveADeckWithCardsWhereFrontIsCatAndBackIsGato(tester);
      await iStartAStudySessionWithStudyFlipped(tester);
      await iShouldSeeGatoAsTheQuestionOnTheFirstCard(tester);
      await tappingTheCardShouldRevealCatAsTheAnswer(tester);
    });
    testWidgets('''Flip icon in study app bar toggles flip state''', (
      tester,
    ) async {
      await iAmStudyingADeckInNormalOrder(tester);
      await iTapTheFlipIconInTheAppBar(tester);
      await theDeckShouldRestartWithBackShownFirst(tester);
      await theFlipIconShouldBeHighlightedToIndicateFlippedMode(tester);
    });
    testWidgets('''Flipped session can also be shuffled''', (tester) async {
      await iAmStudyingAFlippedDeck(tester);
      await iTapTheShuffleIcon(tester);
      await theCardsShouldBeShuffledAndStillShowBackfront(tester);
    });
  });
}
