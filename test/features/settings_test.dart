// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/i_am_on_the_deck_list_screen.dart';
import './step/i_tap_the_settings_icon_in_the_app_bar.dart';
import './step/i_should_be_on_the_settings_screen.dart';
import './step/i_am_signed_in_as_octocat.dart';
import './step/i_navigate_to_the_settings_screen.dart';
import './step/i_should_see_octocat_in_the_account_section.dart';
import './step/i_should_see_a_sign_out_option.dart';
import './step/i_should_see_a_delete_my_account_option.dart';
import './step/i_am_not_signed_in.dart';
import './step/i_should_not_see_the_account_section.dart';
import './step/i_am_signed_in.dart';
import './step/i_tap_sign_out.dart';
import './step/i_should_no_longer_be_signed_in.dart';
import './step/the_account_section_should_no_longer_be_visible.dart';
import './step/i_tap_delete_my_account.dart';
import './step/a_confirmation_dialog_should_appear.dart';
import './step/i_should_see_a_destructive_delete_button_and_a_cancel_button.dart';
import './step/i_tap_cancel_in_the_confirmation_dialog.dart';
import './step/my_account_should_still_exist.dart';
import './step/my_local_data_should_be_unchanged.dart';
import './step/i_am_signed_in_with_local_data_present.dart';
import './step/i_confirm_deletion.dart';
import './step/all_firestore_data_under_my_user_id_should_be_deleted.dart';
import './step/my_firebase_auth_account_should_be_deleted.dart';
import './step/my_local_hive_data_should_be_cleared.dart';
import './step/i_am_on_the_settings_screen.dart';
import './step/i_tap_privacy_policy.dart';
import './step/i_should_see_the_privacy_policy_screen.dart';
import './step/it_should_describe_what_data_is_collected_and_how_to_delete_it.dart';
import './step/i_should_see_a_version_number_in_the_about_section.dart';

void main() {
  group('''Settings''', () {
    testWidgets('''Settings screen is accessible from the deck list''', (
      tester,
    ) async {
      await iAmOnTheDeckListScreen(tester);
      await iTapTheSettingsIconInTheAppBar(tester);
      await iShouldBeOnTheSettingsScreen(tester);
    });
    testWidgets('''Signed-in user sees their account details in Settings''', (
      tester,
    ) async {
      await iAmSignedInAsOctocat(tester);
      await iNavigateToTheSettingsScreen(tester);
      await iShouldSeeOctocatInTheAccountSection(tester);
      await iShouldSeeASignOutOption(tester);
      await iShouldSeeADeleteMyAccountOption(tester);
    });
    testWidgets('''Guest user does not see the Account section''', (
      tester,
    ) async {
      await iAmNotSignedIn(tester);
      await iNavigateToTheSettingsScreen(tester);
      await iShouldNotSeeTheAccountSection(tester);
    });
    testWidgets('''Sign out from Settings''', (tester) async {
      await iAmSignedIn(tester);
      await iNavigateToTheSettingsScreen(tester);
      await iTapSignOut(tester);
      await iShouldNoLongerBeSignedIn(tester);
      await theAccountSectionShouldNoLongerBeVisible(tester);
    });
    testWidgets('''Delete account shows confirmation dialog''', (tester) async {
      await iAmSignedIn(tester);
      await iNavigateToTheSettingsScreen(tester);
      await iTapDeleteMyAccount(tester);
      await aConfirmationDialogShouldAppear(tester);
      await iShouldSeeADestructiveDeleteButtonAndACancelButton(tester);
    });
    testWidgets('''Cancel account deletion leaves data intact''', (
      tester,
    ) async {
      await iAmSignedIn(tester);
      await iNavigateToTheSettingsScreen(tester);
      await iTapDeleteMyAccount(tester);
      await iTapCancelInTheConfirmationDialog(tester);
      await myAccountShouldStillExist(tester);
      await myLocalDataShouldBeUnchanged(tester);
    });
    testWidgets('''Confirmed account deletion removes all data''', (
      tester,
    ) async {
      await iAmSignedInWithLocalDataPresent(tester);
      await iNavigateToTheSettingsScreen(tester);
      await iTapDeleteMyAccount(tester);
      await iConfirmDeletion(tester);
      await allFirestoreDataUnderMyUserIdShouldBeDeleted(tester);
      await myFirebaseAuthAccountShouldBeDeleted(tester);
      await myLocalHiveDataShouldBeCleared(tester);
      await theAccountSectionShouldNoLongerBeVisible(tester);
    });
    testWidgets('''Privacy policy is accessible from Settings''', (
      tester,
    ) async {
      await iAmOnTheSettingsScreen(tester);
      await iTapPrivacyPolicy(tester);
      await iShouldSeeThePrivacyPolicyScreen(tester);
      await itShouldDescribeWhatDataIsCollectedAndHowToDeleteIt(tester);
    });
    testWidgets('''App version is shown in About section''', (tester) async {
      await iAmOnTheSettingsScreen(tester);
      await iShouldSeeAVersionNumberInTheAboutSection(tester);
    });
  });
}
