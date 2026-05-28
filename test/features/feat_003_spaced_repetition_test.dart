// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/i_have_a_deck_with3_new_cards_never_reviewed.dart';
import './step/i_start_a_study_session.dart';
import './step/all3_cards_appear_in_the_session.dart';
import './step/i_have_a_deck_with_cards_that_are_not_yet_due.dart';
import './step/i_see_a_youre_all_caught_up_message.dart';
import './step/i_am_studying_a_new_card.dart';
import './step/i_flip_the_card_and_tap_easy.dart';
import './step/the_cards_next_review_date_is_set_to_tomorrow.dart';
import './step/i_advance_to_the_next_card_automatically.dart';
import './step/i_am_studying_a_card_i_have_reviewed_before.dart';
import './step/i_flip_the_card_and_tap_again.dart';
import './step/the_cards_interval_resets_to1_day_and_the_repetition_count_resets_to0.dart';
import './step/i_am_on_a_card_showing_the_front.dart';
import './step/i_have_not_yet_flipped_the_card.dart';
import './step/i_see_a_tap_card_to_flip_hint_and_no_rating_buttons.dart';
import './step/i_have_a_session_with2_due_cards.dart';
import './step/i_rate_each_card.dart';
import './step/i_see_the_session_complete_screen.dart';

void main() {
  group('''Spaced Repetition (SM-2)''', () {
    testWidgets('''New cards are always shown in a study session''', (
      tester,
    ) async {
      await iHaveADeckWith3NewCardsNeverReviewed(tester);
      await iStartAStudySession(tester);
      await all3CardsAppearInTheSession(tester);
    });
    testWidgets('''Cards with a future review date are excluded''', (
      tester,
    ) async {
      await iHaveADeckWithCardsThatAreNotYetDue(tester);
      await iStartAStudySession(tester);
      await iSeeAYoureAllCaughtUpMessage(tester);
    });
    testWidgets('''Rating a card as Easy defers it by 1 day''', (tester) async {
      await iAmStudyingANewCard(tester);
      await iFlipTheCardAndTapEasy(tester);
      await theCardsNextReviewDateIsSetToTomorrow(tester);
      await iAdvanceToTheNextCardAutomatically(tester);
    });
    testWidgets('''Rating a card as Again resets it to tomorrow''', (
      tester,
    ) async {
      await iAmStudyingACardIHaveReviewedBefore(tester);
      await iFlipTheCardAndTapAgain(tester);
      await theCardsIntervalResetsTo1DayAndTheRepetitionCountResetsTo0(tester);
    });
    testWidgets('''Rating buttons appear only after flipping''', (
      tester,
    ) async {
      await iAmOnACardShowingTheFront(tester);
      await iHaveNotYetFlippedTheCard(tester);
      await iSeeATapCardToFlipHintAndNoRatingButtons(tester);
    });
    testWidgets('''Session completes after all due cards are rated''', (
      tester,
    ) async {
      await iHaveASessionWith2DueCards(tester);
      await iRateEachCard(tester);
      await iSeeTheSessionCompleteScreen(tester);
    });
  });
}
