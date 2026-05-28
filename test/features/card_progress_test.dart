// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_deck_contains_a_card_with0_stars.dart';
import './step/i_tap_the_star_button_on_that_card.dart';
import './step/the_card_should_show1_star.dart';
import './step/the_card_should_not_be_archived.dart';
import './step/a_deck_contains_a_card_with1_star.dart';
import './step/the_card_should_show2_stars.dart';
import './step/a_deck_contains_a_card_with2_stars.dart';
import './step/the_card_should_be_archived.dart';
import './step/the_card_should_no_longer_appear_in_the_active_card_list.dart';
import './step/the_card_should_appear_in_the_archived_section.dart';
import './step/a_deck_contains3_active_cards_and1_archived_card.dart';
import './step/i_start_a_study_session_for_that_deck.dart';
import './step/the_session_should_contain3_cards.dart';
import './step/the_archived_card_should_not_appear.dart';
import './step/a_deck_contains_cards_with_star_counts01_and2.dart';
import './step/i_start_a_study_session_in_order.dart';
import './step/cards_with_more_stars_should_appear_later_in_the_session.dart';
import './step/a_deck_contains_an_archived_card.dart';
import './step/i_tap_unarchive_on_that_card_in_the_archived_section.dart';
import './step/the_card_should_be_returned_to_the_active_list_with0_stars.dart';
import './step/i_am_studying_a_deck_with_at_least_one_card.dart';
import './step/i_should_see_a_star_button_below_the_navigation_buttons.dart';
import './step/it_should_show_the_current_star_count_for_the_visible_card.dart';
import './step/i_am_studying_a_deck_and_viewing_a_card_with1_star.dart';
import './step/i_tap_the_star_button_during_the_study_session.dart';
import './step/the_cards_star_count_should_increment_to2.dart';
import './step/the_star_button_should_update_immediately.dart';
import './step/i_am_signed_in.dart';
import './step/i_have_a_card_with2_stars.dart';
import './step/i_tap_back_up_now.dart';
import './step/the_card_in_firestore_should_have_starcount2_and_archived_false.dart';
import './step/firestore_contains_a_card_with_starcount3_and_archived_true.dart';
import './step/i_tap_restore.dart';
import './step/the_local_card_should_have_starcount3_and_archived_true.dart';

void main() {
  group('''Card Progress Tracking''', () {
    testWidgets('''Star a card for the first time''', (tester) async {
      await aDeckContainsACardWith0Stars(tester);
      await iTapTheStarButtonOnThatCard(tester);
      await theCardShouldShow1Star(tester);
      await theCardShouldNotBeArchived(tester);
    });
    testWidgets('''Star a card a second time''', (tester) async {
      await aDeckContainsACardWith1Star(tester);
      await iTapTheStarButtonOnThatCard(tester);
      await theCardShouldShow2Stars(tester);
      await theCardShouldNotBeArchived(tester);
    });
    testWidgets('''Starring a card for the third time archives it''', (
      tester,
    ) async {
      await aDeckContainsACardWith2Stars(tester);
      await iTapTheStarButtonOnThatCard(tester);
      await theCardShouldBeArchived(tester);
      await theCardShouldNoLongerAppearInTheActiveCardList(tester);
      await theCardShouldAppearInTheArchivedSection(tester);
    });
    testWidgets('''Archived cards are excluded from study sessions''', (
      tester,
    ) async {
      await aDeckContains3ActiveCardsAnd1ArchivedCard(tester);
      await iStartAStudySessionForThatDeck(tester);
      await theSessionShouldContain3Cards(tester);
      await theArchivedCardShouldNotAppear(tester);
    });
    testWidgets(
      '''Archived cards are sorted to the back during study (pre-archive)''',
      (tester) async {
        await aDeckContainsCardsWithStarCounts01And2(tester);
        await iStartAStudySessionInOrder(tester);
        await cardsWithMoreStarsShouldAppearLaterInTheSession(tester);
      },
    );
    testWidgets('''Unarchive a card resets its star count''', (tester) async {
      await aDeckContainsAnArchivedCard(tester);
      await iTapUnarchiveOnThatCardInTheArchivedSection(tester);
      await theCardShouldBeReturnedToTheActiveListWith0Stars(tester);
    });
    testWidgets('''Star button is visible during a study session''', (
      tester,
    ) async {
      await iAmStudyingADeckWithAtLeastOneCard(tester);
      await iShouldSeeAStarButtonBelowTheNavigationButtons(tester);
      await itShouldShowTheCurrentStarCountForTheVisibleCard(tester);
    });
    testWidgets('''Star a card during a study session''', (tester) async {
      await iAmStudyingADeckAndViewingACardWith1Star(tester);
      await iTapTheStarButtonDuringTheStudySession(tester);
      await theCardsStarCountShouldIncrementTo2(tester);
      await theStarButtonShouldUpdateImmediately(tester);
    });
    testWidgets(
      '''Star count and archived status are backed up to Firestore''',
      (tester) async {
        await iAmSignedIn(tester);
        await iHaveACardWith2Stars(tester);
        await iTapBackUpNow(tester);
        await theCardInFirestoreShouldHaveStarcount2AndArchivedFalse(tester);
      },
    );
    testWidgets(
      '''Star count and archived status are restored from Firestore''',
      (tester) async {
        await iAmSignedIn(tester);
        await firestoreContainsACardWithStarcount3AndArchivedTrue(tester);
        await iTapRestore(tester);
        await theLocalCardShouldHaveStarcount3AndArchivedTrue(tester);
      },
    );
  });
}
