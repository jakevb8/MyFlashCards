// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/i_have_a_deck_named_french_words_with3_cards.dart';
import './step/i_open_the_deck.dart';
import './step/i_should_see_all3_cards_immediately.dart';
import './step/i_have_a_deck_named_french_words.dart';
import './step/i_add_a_card_with_front_bonjour_and_back_hello.dart';
import './step/i_should_see_bonjour_in_the_card_list.dart';
import './step/i_have_a_card_with_front_hola_and_back_hi.dart';
import './step/i_edit_the_card_to_have_front_hola_and_back_hello.dart';
import './step/the_card_should_show_hello_as_the_back.dart';
import './step/i_have_a_card_with_front_delete_me_in_the_deck.dart';
import './step/i_swipe_left_on_the_card.dart';
import './step/i_tap_delete.dart';
import './step/i_should_not_see_delete_me_in_the_card_list.dart';
import './step/i_have_at_least_one_card_in_a_deck.dart';
import './step/i_am_on_the_card_list_screen.dart';
import './step/i_should_see_the_hint_swipe_left_on_a_card_to_edit_or_delete.dart';
import './step/i_am_adding_a_card_to_a_deck.dart';
import './step/i_submit_with_an_empty_front.dart';
import './step/i_should_see_a_validation_error.dart';
import './step/i_submit_with_an_empty_back.dart';
import './step/a_flashcard_is_created_with_a_preassigned_id_and_deckid.dart';
import './step/the_flashcard_stored_in_the_repository_should_have_that_same_id_and_deckid.dart';
import './step/it_should_not_be_replaced_with_a_new_uuid.dart';

void main() {
  group('''Flashcard Management''', () {
    testWidgets('''Cards load automatically when opening a deck''', (
      tester,
    ) async {
      await iHaveADeckNamedFrenchWordsWith3Cards(tester);
      await iOpenTheDeck(tester);
      await iShouldSeeAll3CardsImmediately(tester);
    });
    testWidgets('''Add a flashcard to a deck''', (tester) async {
      await iHaveADeckNamedFrenchWords(tester);
      await iAddACardWithFrontBonjourAndBackHello(tester);
      await iShouldSeeBonjourInTheCardList(tester);
    });
    testWidgets('''Edit a flashcard''', (tester) async {
      await iHaveACardWithFrontHolaAndBackHi(tester);
      await iEditTheCardToHaveFrontHolaAndBackHello(tester);
      await theCardShouldShowHelloAsTheBack(tester);
    });
    testWidgets('''Delete a flashcard via swipe''', (tester) async {
      await iHaveACardWithFrontDeleteMeInTheDeck(tester);
      await iSwipeLeftOnTheCard(tester);
      await iTapDelete(tester);
      await iShouldNotSeeDeleteMeInTheCardList(tester);
    });
    testWidgets('''Swipe hint is visible when cards exist''', (tester) async {
      await iHaveAtLeastOneCardInADeck(tester);
      await iAmOnTheCardListScreen(tester);
      await iShouldSeeTheHintSwipeLeftOnACardToEditOrDelete(tester);
    });
    testWidgets('''Cannot add a card without front text''', (tester) async {
      await iAmAddingACardToADeck(tester);
      await iSubmitWithAnEmptyFront(tester);
      await iShouldSeeAValidationError(tester);
    });
    testWidgets('''Cannot add a card without back text''', (tester) async {
      await iAmAddingACardToADeck(tester);
      await iSubmitWithAnEmptyBack(tester);
      await iShouldSeeAValidationError(tester);
    });
    testWidgets('''Flashcard ID is preserved when created programmatically''', (
      tester,
    ) async {
      await aFlashcardIsCreatedWithAPreassignedIdAndDeckid(tester);
      await theFlashcardStoredInTheRepositoryShouldHaveThatSameIdAndDeckid(
        tester,
      );
      await itShouldNotBeReplacedWithANewUuid(tester);
    });
  });
}
