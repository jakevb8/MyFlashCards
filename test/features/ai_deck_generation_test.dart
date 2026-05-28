// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/i_am_on_the_deck_list_screen.dart';
import './step/i_tap_generate_with_ai.dart';
import './step/i_enter_the_topic_cvc_words_for_a_beginning_reader.dart';
import './step/i_tap_generate_cards.dart';
import './step/a_new_deck_named_cvc_words_for_a_beginning_reader_should_be_created.dart';
import './step/the_deck_should_contain_flashcards_with_words_on_the_front_and_definitions_or_examples_on_the_back.dart';
import './step/i_am_on_the_ai_generation_screen.dart';
import './step/i_tap_generate_cards_with_topic_animals.dart';
import './step/each_card_front_should_contain_the_word_or_term_itself_eg_cat.dart';
import './step/no_card_front_should_be_phrased_as_what_word_is_spelled_cat.dart';
import './step/card_backs_should_be_a_concise_onesentence_definition_or_example.dart';
import './step/i_have_entered_the_topic_cvc_words_for_a_beginning_reader.dart';
import './step/i_should_see_a_preview_list_of_generated_cards.dart';
import './step/i_should_be_able_to_remove_individual_cards_before_saving.dart';
import './step/i_should_be_able_to_tap_save_n_to_keep_them.dart';
import './step/i_have_previewed_generated_cards_for_cvc_words.dart';
import './step/i_tap_regenerate.dart';
import './step/a_new_set_of_cards_should_be_generated_for_the_same_topic.dart';
import './step/i_request20_cards_on_the_ai_generation_screen.dart';
import './step/the_ai_returns_more_than20_results.dart';
import './step/the_preview_should_contain_exactly20_cards.dart';
import './step/i_move_the_cards_to_generate_slider_to50.dart';
import './step/the_card_count_badge_should_show50.dart';
import './step/i_tap_the_card_count_badge.dart';
import './step/i_type75_in_the_dialog.dart';
import './step/i_tap_ok.dart';
import './step/the_card_count_should_be_set_to75.dart';
import './step/i_tap_the_count_badge_and_enter150.dart';
import './step/the_dialog_should_not_accept_the_value_and_the_count_should_remain_unchanged.dart';
import './step/i_have_previewed15_generated_cards_for_animals.dart';
import './step/i_tap_load_more_cards.dart';
import './step/the_ai_should_be_called_again_with_the_existing_card_fronts_as_an_exclusion_list.dart';
import './step/any_returned_cards_whose_front_matches_an_alreadypreviewed_card_should_be_filtered_out.dart';
import './step/a_snackbar_should_report_how_many_new_cards_were_added.dart';
import './step/if_no_new_unique_cards_are_found_a_message_no_new_cards_found_try_rephrasing_your_topic_should_appear.dart';
import './step/i_have_uploaded_a_document_and_generated_cards_from_it.dart';
import './step/the_load_more_cards_button_should_not_be_visible.dart';
import './step/i_have_an_existing_deck_named_animals.dart';
import './step/i_select_animals_in_the_save_to_dropdown.dart';
import './step/i_tap_save.dart';
import './step/any_cards_whose_front_matches_an_existing_card_should_be_skipped.dart';
import './step/only_new_unique_cards_should_be_added_to_animals.dart';
import './step/a_snackbar_should_report_how_many_were_added_and_how_many_were_skipped.dart';
import './step/the_decks_id_and_each_flashcards_deckid_should_match.dart';
import './step/all_generated_cards_should_appear_when_the_deck_is_opened.dart';
import './step/i_tap_upload_document.dart';
import './step/i_select_a_plain_text_or_markdown_file.dart';
import './step/the_document_content_should_be_parsed.dart';
import './step/flashcard_suggestions_should_be_extracted_from_the_content.dart';
import './step/the_capitalise_first_letter_toggle_should_be_on_by_default.dart';
import './step/each_card_front_and_back_should_start_with_a_capital_letter.dart';
import './step/i_turn_off_the_capitalise_first_letter_toggle.dart';
import './step/card_fronts_and_backs_should_be_returned_exactly_as_the_ai_produced_them.dart';
import './step/i_tap_generate_cards_with_no_topic_entered_and_no_file_selected.dart';
import './step/i_should_see_a_validation_message.dart';
import './step/the_ai_service_is_unavailable.dart';
import './step/i_should_see_an_error_message.dart';
import './step/no_deck_should_be_created.dart';
import './step/no_gemini_api_key_has_been_saved_in_secure_storage.dart';
import './step/i_should_see_a_snackbar_with_the_message_add_your_gemini_api_key_in_settings_first.dart';
import './step/the_snackbar_should_contain_a_settings_action_button.dart';
import './step/no_generation_request_should_be_made.dart';
import './step/no_gemini_api_key_has_been_saved.dart';
import './step/i_tap_the_settings_action_in_the_snackbar.dart';
import './step/i_should_be_navigated_to_the_settings_screen.dart';
import './step/the_settings_screen_should_show_the_ai_settings_section.dart';
import './step/a_gemini_api_key_aizasyfakekeyfortestingpurposesonly12_is_saved_in_secure_storage.dart';
import './step/the_generation_request_should_be_made_using_the_stored_key.dart';
import './step/i_should_see_the_card_preview.dart';
import './step/a_gemini_api_key_aizasyfakekeyfortestingpurposesonly12_has_been_saved.dart';
import './step/the_aigeneratescreen_is_initialised.dart';
import './step/geminikeyservicereadkey_should_be_called.dart';
import './step/the_key_should_be_loaded_into_state_before_the_first_user_interaction.dart';
import './step/the_generate_cards_button_should_be_functional_without_additional_setup.dart';
import './step/i_am_on_the_settings_screen.dart';
import './step/i_tap_edit_api_key.dart';
import './step/i_enter_aizasyfakekeyfortestingpurposesonly12_in_the_key_field.dart';
import './step/the_key_status_tile_should_show_key_saved.dart';
import './step/the_bottom_sheet_should_close_automatically.dart';
import './step/i_enter_notavalidkey_in_the_key_field.dart';
import './step/an_inline_error_should_appear_below_the_text_field.dart';
import './step/the_key_should_not_be_written_to_secure_storage.dart';
import './step/the_bottom_sheet_should_remain_open.dart';
import './step/a_gemini_api_key_is_saved.dart';
import './step/i_tap_clear.dart';
import './step/the_key_status_tile_should_show_no_key_saved.dart';
import './step/geminikeyserviceclearkey_should_have_been_called.dart';
import './step/i_tap_how_to_get_a_key.dart';
import './step/the_gemini_key_walkthrough_screen_should_be_pushed_onto_the_navigator.dart';
import './step/it_should_show4_pages_with_a_page_indicator.dart';
import './step/i_am_on_the_gemini_key_walkthrough_screen.dart';
import './step/i_tap_skip.dart';
import './step/the_walkthrough_should_be_popped_from_the_navigator.dart';
import './step/i_have_navigated_to_the_last_page.dart';
import './step/i_tap_done.dart';

void main() {
  group('''AI Deck Generation''', () {
    testWidgets('''Generate a deck from a topic prompt''', (tester) async {
      await iAmOnTheDeckListScreen(tester);
      await iTapGenerateWithAi(tester);
      await iEnterTheTopicCvcWordsForABeginningReader(tester);
      await iTapGenerateCards(tester);
      await aNewDeckNamedCvcWordsForABeginningReaderShouldBeCreated(tester);
      await theDeckShouldContainFlashcardsWithWordsOnTheFrontAndDefinitionsOrExamplesOnTheBack(
        tester,
      );
    });
    testWidgets(
      '''Card fronts contain the word itself, not a spelling question''',
      (tester) async {
        await iAmOnTheAiGenerationScreen(tester);
        await iTapGenerateCardsWithTopicAnimals(tester);
        await eachCardFrontShouldContainTheWordOrTermItselfEgCat(tester);
        await noCardFrontShouldBePhrasedAsWhatWordIsSpelledCat(tester);
        await cardBacksShouldBeAConciseOnesentenceDefinitionOrExample(tester);
      },
    );
    testWidgets('''Preview generated cards before saving''', (tester) async {
      await iHaveEnteredTheTopicCvcWordsForABeginningReader(tester);
      await iTapGenerateCards(tester);
      await iShouldSeeAPreviewListOfGeneratedCards(tester);
      await iShouldBeAbleToRemoveIndividualCardsBeforeSaving(tester);
      await iShouldBeAbleToTapSaveNToKeepThem(tester);
    });
    testWidgets('''Regenerate cards if not satisfied''', (tester) async {
      await iHavePreviewedGeneratedCardsForCvcWords(tester);
      await iTapRegenerate(tester);
      await aNewSetOfCardsShouldBeGeneratedForTheSameTopic(tester);
    });
    testWidgets('''Result count is always capped at the requested number''', (
      tester,
    ) async {
      await iRequest20CardsOnTheAiGenerationScreen(tester);
      await theAiReturnsMoreThan20Results(tester);
      await thePreviewShouldContainExactly20Cards(tester);
    });
    testWidgets('''Adjust card count via slider up to 100''', (tester) async {
      await iAmOnTheAiGenerationScreen(tester);
      await iMoveTheCardsToGenerateSliderTo50(tester);
      await theCardCountBadgeShouldShow50(tester);
    });
    testWidgets('''Enter a custom card count by tapping the count badge''', (
      tester,
    ) async {
      await iAmOnTheAiGenerationScreen(tester);
      await iTapTheCardCountBadge(tester);
      await iType75InTheDialog(tester);
      await iTapOk(tester);
      await theCardCountShouldBeSetTo75(tester);
    });
    testWidgets('''Custom card count is clamped between 1 and 100''', (
      tester,
    ) async {
      await iAmOnTheAiGenerationScreen(tester);
      await iTapTheCountBadgeAndEnter150(tester);
      await theDialogShouldNotAcceptTheValueAndTheCountShouldRemainUnchanged(
        tester,
      );
    });
    testWidgets('''Load more cards without duplicates''', (tester) async {
      await iHavePreviewed15GeneratedCardsForAnimals(tester);
      await iTapLoadMoreCards(tester);
      await theAiShouldBeCalledAgainWithTheExistingCardFrontsAsAnExclusionList(
        tester,
      );
      await anyReturnedCardsWhoseFrontMatchesAnAlreadypreviewedCardShouldBeFilteredOut(
        tester,
      );
      await aSnackbarShouldReportHowManyNewCardsWereAdded(tester);
      await ifNoNewUniqueCardsAreFoundAMessageNoNewCardsFoundTryRephrasingYourTopicShouldAppear(
        tester,
      );
    });
    testWidgets('''Load More is not shown for file-based generation''', (
      tester,
    ) async {
      await iHaveUploadedADocumentAndGeneratedCardsFromIt(tester);
      await theLoadMoreCardsButtonShouldNotBeVisible(tester);
    });
    testWidgets(
      '''Add generated cards to an existing deck with duplicate skipping''',
      (tester) async {
        await iHaveAnExistingDeckNamedAnimals(tester);
        await iSelectAnimalsInTheSaveToDropdown(tester);
        await iTapGenerateCards(tester);
        await iTapSave(tester);
        await anyCardsWhoseFrontMatchesAnExistingCardShouldBeSkipped(tester);
        await onlyNewUniqueCardsShouldBeAddedToAnimals(tester);
        await aSnackbarShouldReportHowManyWereAddedAndHowManyWereSkipped(
          tester,
        );
      },
    );
    testWidgets('''Saved cards and deck share the same ID''', (tester) async {
      await iTapGenerateCardsWithTopicAnimals(tester);
      await iTapSave(tester);
      await theDecksIdAndEachFlashcardsDeckidShouldMatch(tester);
      await allGeneratedCardsShouldAppearWhenTheDeckIsOpened(tester);
    });
    testWidgets('''Generate a deck from an uploaded text file''', (
      tester,
    ) async {
      await iTapGenerateWithAi(tester);
      await iTapUploadDocument(tester);
      await iSelectAPlainTextOrMarkdownFile(tester);
      await theDocumentContentShouldBeParsed(tester);
      await flashcardSuggestionsShouldBeExtractedFromTheContent(tester);
    });
    testWidgets('''Capitalise first letter toggle defaults to on''', (
      tester,
    ) async {
      await iAmOnTheAiGenerationScreen(tester);
      await theCapitaliseFirstLetterToggleShouldBeOnByDefault(tester);
      await iTapGenerateCardsWithTopicAnimals(tester);
      await eachCardFrontAndBackShouldStartWithACapitalLetter(tester);
    });
    testWidgets('''Turning off capitalisation preserves AI casing''', (
      tester,
    ) async {
      await iAmOnTheAiGenerationScreen(tester);
      await iTurnOffTheCapitaliseFirstLetterToggle(tester);
      await iTapGenerateCardsWithTopicAnimals(tester);
      await cardFrontsAndBacksShouldBeReturnedExactlyAsTheAiProducedThem(
        tester,
      );
      await iAmOnTheAiGenerationScreen(tester);
      await iTapGenerateCardsWithNoTopicEnteredAndNoFileSelected(tester);
      await iShouldSeeAValidationMessage(tester);
    });
    testWidgets('''Generation failure shows an error''', (tester) async {
      await theAiServiceIsUnavailable(tester);
      await iTapGenerateCardsWithTopicAnimals(tester);
      await iShouldSeeAnErrorMessage(tester);
      await noDeckShouldBeCreated(tester);
    });
    testWidgets('''User with no key set sees prompt to add key in Settings''', (
      tester,
    ) async {
      await iAmOnTheAiGenerationScreen(tester);
      await noGeminiApiKeyHasBeenSavedInSecureStorage(tester);
      await iTapGenerateCardsWithTopicAnimals(tester);
      await iShouldSeeASnackbarWithTheMessageAddYourGeminiApiKeyInSettingsFirst(
        tester,
      );
      await theSnackbarShouldContainASettingsActionButton(tester);
      await noGenerationRequestShouldBeMade(tester);
    });
    testWidgets(
      '''Tapping Settings action from no-key snackbar opens Settings screen''',
      (tester) async {
        await iAmOnTheAiGenerationScreen(tester);
        await noGeminiApiKeyHasBeenSaved(tester);
        await iTapGenerateCards(tester);
        await iTapTheSettingsActionInTheSnackbar(tester);
        await iShouldBeNavigatedToTheSettingsScreen(tester);
        await theSettingsScreenShouldShowTheAiSettingsSection(tester);
      },
    );
    testWidgets('''User with key set can generate cards''', (tester) async {
      await aGeminiApiKeyAizasyfakekeyfortestingpurposesonly12IsSavedInSecureStorage(
        tester,
      );
      await iAmOnTheAiGenerationScreen(tester);
      await iTapGenerateCardsWithTopicAnimals(tester);
      await theGenerationRequestShouldBeMadeUsingTheStoredKey(tester);
      await iShouldSeeTheCardPreview(tester);
    });
    testWidgets(
      '''Key survives app restart (loaded from secure storage on init)''',
      (tester) async {
        await aGeminiApiKeyAizasyfakekeyfortestingpurposesonly12HasBeenSaved(
          tester,
        );
        await theAigeneratescreenIsInitialised(tester);
        await geminikeyservicereadkeyShouldBeCalled(tester);
        await theKeyShouldBeLoadedIntoStateBeforeTheFirstUserInteraction(
          tester,
        );
        await theGenerateCardsButtonShouldBeFunctionalWithoutAdditionalSetup(
          tester,
        );
      },
    );
    testWidgets(
      '''Saving a valid key in Settings updates the AI generate screen''',
      (tester) async {
        await iAmOnTheSettingsScreen(tester);
        await iTapEditApiKey(tester);
        await iEnterAizasyfakekeyfortestingpurposesonly12InTheKeyField(tester);
        await iTapSave(tester);
        await theKeyStatusTileShouldShowKeySaved(tester);
        await theBottomSheetShouldCloseAutomatically(tester);
      },
    );
    testWidgets('''Saving an invalid key shows inline validation error''', (
      tester,
    ) async {
      await iAmOnTheSettingsScreen(tester);
      await iTapEditApiKey(tester);
      await iEnterNotavalidkeyInTheKeyField(tester);
      await iTapSave(tester);
      await anInlineErrorShouldAppearBelowTheTextField(tester);
      await theKeyShouldNotBeWrittenToSecureStorage(tester);
      await theBottomSheetShouldRemainOpen(tester);
    });
    testWidgets('''Clearing the key in Settings resets status to not set''', (
      tester,
    ) async {
      await aGeminiApiKeyIsSaved(tester);
      await iAmOnTheSettingsScreen(tester);
      await iTapEditApiKey(tester);
      await iTapClear(tester);
      await theKeyStatusTileShouldShowNoKeySaved(tester);
      await geminikeyserviceclearkeyShouldHaveBeenCalled(tester);
    });
    testWidgets('''Walkthrough is accessible from the key bottom sheet''', (
      tester,
    ) async {
      await iAmOnTheSettingsScreen(tester);
      await iTapEditApiKey(tester);
      await iTapHowToGetAKey(tester);
      await theGeminiKeyWalkthroughScreenShouldBePushedOntoTheNavigator(tester);
      await itShouldShow4PagesWithAPageIndicator(tester);
    });
    testWidgets('''Walkthrough Skip button closes the walkthrough''', (
      tester,
    ) async {
      await iAmOnTheGeminiKeyWalkthroughScreen(tester);
      await iTapSkip(tester);
      await theWalkthroughShouldBePoppedFromTheNavigator(tester);
    });
    testWidgets(
      '''Walkthrough Done button on last page closes the walkthrough''',
      (tester) async {
        await iAmOnTheGeminiKeyWalkthroughScreen(tester);
        await iHaveNavigatedToTheLastPage(tester);
        await iTapDone(tester);
        await theWalkthroughShouldBePoppedFromTheNavigator(tester);
      },
    );
  });
}
