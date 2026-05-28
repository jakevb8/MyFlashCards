// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/i_have_no_decks.dart';
import './step/i_create_a_deck_named_spanish_vocabulary.dart';
import './step/i_should_see_spanish_vocabulary_in_my_deck_list.dart';
import './step/i_create_a_deck_named_geography_with_description_world_capitals.dart';
import './step/i_should_see_geography_in_my_deck_list.dart';
import './step/i_have_a_deck_named_maths.dart';
import './step/i_rename_it_to_advanced_maths.dart';
import './step/i_should_see_advanced_maths_in_my_deck_list.dart';
import './step/i_should_not_see_maths_in_my_deck_list.dart';
import './step/i_have_a_deck_named_old_deck.dart';
import './step/i_swipe_left_on_the_deck.dart';
import './step/i_tap_delete.dart';
import './step/i_confirm_the_deletion_in_the_dialog.dart';
import './step/i_should_not_see_old_deck_in_my_deck_list.dart';
import './step/i_have_at_least_one_deck.dart';
import './step/i_am_on_the_deck_list_screen.dart';
import './step/i_should_see_the_hint_swipe_left_on_a_deck_to_edit_or_delete.dart';
import './step/i_try_to_create_a_deck_with_an_empty_name.dart';
import './step/i_should_see_a_validation_error.dart';
import './step/a_deck_is_created_with_a_preassigned_id.dart';
import './step/the_deck_stored_in_the_repository_should_have_that_same_id.dart';
import './step/it_should_not_be_replaced_with_a_new_uuid.dart';
import './step/i_have_a_deck_named_french_words_with3_cards.dart';
import './step/i_have_a_deck_tagged_science_and_a_deck_tagged_history.dart';
import './step/i_filter_by_the_tag_science.dart';
import './step/i_should_only_see_the_science_deck.dart';
import './step/i_have_two_decks_each_with_due_cards.dart';
import './step/i_long_press_the_first_deck_to_enter_multi_select_mode.dart';
import './step/i_tap_the_second_deck_to_select_it.dart';
import './step/i_tap_study_selected.dart';
import './step/the_study_session_should_start_with_cards_from_both_decks.dart';

void main() {
  group('''Deck Management''', () {
    testWidgets('''Create a new deck''', (tester) async {
      await iHaveNoDecks(tester);
      await iCreateADeckNamedSpanishVocabulary(tester);
      await iShouldSeeSpanishVocabularyInMyDeckList(tester);
    });
    testWidgets('''Create a deck with description''', (tester) async {
      await iHaveNoDecks(tester);
      await iCreateADeckNamedGeographyWithDescriptionWorldCapitals(tester);
      await iShouldSeeGeographyInMyDeckList(tester);
    });
    testWidgets('''Edit an existing deck''', (tester) async {
      await iHaveADeckNamedMaths(tester);
      await iRenameItToAdvancedMaths(tester);
      await iShouldSeeAdvancedMathsInMyDeckList(tester);
      await iShouldNotSeeMathsInMyDeckList(tester);
    });
    testWidgets('''Delete a deck via swipe''', (tester) async {
      await iHaveADeckNamedOldDeck(tester);
      await iSwipeLeftOnTheDeck(tester);
      await iTapDelete(tester);
      await iConfirmTheDeletionInTheDialog(tester);
      await iShouldNotSeeOldDeckInMyDeckList(tester);
    });
    testWidgets('''Swipe hint is visible when decks exist''', (tester) async {
      await iHaveAtLeastOneDeck(tester);
      await iAmOnTheDeckListScreen(tester);
      await iShouldSeeTheHintSwipeLeftOnADeckToEditOrDelete(tester);
    });
    testWidgets('''Cannot create a deck without a name''', (tester) async {
      await iHaveNoDecks(tester);
      await iTryToCreateADeckWithAnEmptyName(tester);
      await iShouldSeeAValidationError(tester);
    });
    testWidgets('''Deck ID is preserved when created programmatically''', (
      tester,
    ) async {
      await aDeckIsCreatedWithAPreassignedId(tester);
      await theDeckStoredInTheRepositoryShouldHaveThatSameId(tester);
      await itShouldNotBeReplacedWithANewUuid(tester);
    });
    testWidgets('''Deck tile shows per-deck progress stats''', (tester) async {
      await iHaveADeckNamedFrenchWordsWith3Cards(tester);
      await iAmOnTheDeckListScreen(tester);
      await iShouldSeeTheHintSwipeLeftOnADeckToEditOrDelete(tester);
    });
    testWidgets('''Filter decks by tag''', (tester) async {
      await iHaveADeckTaggedScienceAndADeckTaggedHistory(tester);
      await iFilterByTheTagScience(tester);
      await iShouldOnlySeeTheScienceDeck(tester);
    });
    testWidgets('''Study cards from multiple selected decks''', (tester) async {
      await iHaveTwoDecksEachWithDueCards(tester);
      await iLongPressTheFirstDeckToEnterMultiSelectMode(tester);
      await iTapTheSecondDeckToSelectIt(tester);
      await iTapStudySelected(tester);
      await theStudySessionShouldStartWithCardsFromBothDecks(tester);
    });
  });
}
