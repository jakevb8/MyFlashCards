// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/the_app_has_just_launched.dart';
import './step/the_active_theme_should_be_classic.dart';
import './step/the_brightness_should_be_system.dart';
import './step/kids_mode_should_be_off.dart';
import './step/i_have_selected_the_ocean_blue_theme_with_dark_brightness.dart';
import './step/i_close_and_relaunch_the_app.dart';
import './step/the_active_theme_should_be_ocean_blue.dart';
import './step/the_brightness_should_be_dark.dart';
import './step/the_app_is_on_the_classic_theme.dart';
import './step/i_open_the_theme_picker.dart';
import './step/i_select_the_ocean_blue_theme.dart';
import './step/i_select_the_rose_garden_theme.dart';
import './step/the_active_theme_should_be_rose_garden.dart';
import './step/i_select_the_executive_theme.dart';
import './step/the_active_theme_should_be_executive.dart';
import './step/the_brightness_is_system.dart';
import './step/i_select_dark_brightness.dart';
import './step/the_brightness_is_dark.dart';
import './step/i_select_light_brightness.dart';
import './step/the_brightness_should_be_light.dart';
import './step/the_brightness_is_light.dart';
import './step/i_select_system_brightness.dart';
import './step/the_app_is_on_the_classic_theme_with_kids_mode_off.dart';
import './step/i_toggle_kids_mode_on.dart';
import './step/kids_mode_should_be_on.dart';
import './step/the_active_theme_should_be_sunshine.dart';
import './step/the_theme_picker_should_show_kids_themes_sunshine_jungle_bubblegum_super_hero.dart';
import './step/kids_mode_is_on_with_theme_sunshine.dart';
import './step/i_toggle_kids_mode_off.dart';
import './step/kids_mode_is_on.dart';
import './step/i_select_the_bubblegum_theme.dart';
import './step/the_active_theme_should_be_bubblegum.dart';
import './step/kids_mode_is_on_with_theme_jungle.dart';
import './step/the_active_theme_should_be_jungle.dart';
import './step/the_app_is_on_the_classic_theme_with_system_brightness.dart';

void main() {
  group('''Theme Selection''', () {
    testWidgets('''Default theme is Classic (adult)''', (tester) async {
      await theAppHasJustLaunched(tester);
      await theActiveThemeShouldBeClassic(tester);
      await theBrightnessShouldBeSystem(tester);
      await kidsModeShouldBeOff(tester);
    });
    testWidgets('''Theme choice persists across app restarts''', (
      tester,
    ) async {
      await iHaveSelectedTheOceanBlueThemeWithDarkBrightness(tester);
      await iCloseAndRelaunchTheApp(tester);
      await theActiveThemeShouldBeOceanBlue(tester);
      await theBrightnessShouldBeDark(tester);
    });
    testWidgets('''Switch to Ocean Blue theme''', (tester) async {
      await theAppIsOnTheClassicTheme(tester);
      await iOpenTheThemePicker(tester);
      await iSelectTheOceanBlueTheme(tester);
      await theActiveThemeShouldBeOceanBlue(tester);
    });
    testWidgets('''Switch to Rose Garden theme''', (tester) async {
      await theAppIsOnTheClassicTheme(tester);
      await iOpenTheThemePicker(tester);
      await iSelectTheRoseGardenTheme(tester);
      await theActiveThemeShouldBeRoseGarden(tester);
    });
    testWidgets('''Switch to Executive theme''', (tester) async {
      await theAppIsOnTheClassicTheme(tester);
      await iOpenTheThemePicker(tester);
      await iSelectTheExecutiveTheme(tester);
      await theActiveThemeShouldBeExecutive(tester);
    });
    testWidgets('''Set brightness to Dark''', (tester) async {
      await theBrightnessIsSystem(tester);
      await iOpenTheThemePicker(tester);
      await iSelectDarkBrightness(tester);
      await theBrightnessShouldBeDark(tester);
    });
    testWidgets('''Set brightness to Light''', (tester) async {
      await theBrightnessIsDark(tester);
      await iOpenTheThemePicker(tester);
      await iSelectLightBrightness(tester);
      await theBrightnessShouldBeLight(tester);
    });
    testWidgets('''Set brightness back to System''', (tester) async {
      await theBrightnessIsLight(tester);
      await iOpenTheThemePicker(tester);
      await iSelectSystemBrightness(tester);
      await theBrightnessShouldBeSystem(tester);
    });
    testWidgets('''Toggle to kids mode shows kids themes''', (tester) async {
      await theAppIsOnTheClassicThemeWithKidsModeOff(tester);
      await iOpenTheThemePicker(tester);
      await iToggleKidsModeOn(tester);
      await kidsModeShouldBeOn(tester);
      await theActiveThemeShouldBeSunshine(tester);
      await theThemePickerShouldShowKidsThemesSunshineJungleBubblegumSuperHero(
        tester,
      );
    });
    testWidgets('''Toggle back to adult mode restores adult themes''', (
      tester,
    ) async {
      await kidsModeIsOnWithThemeSunshine(tester);
      await iOpenTheThemePicker(tester);
      await iToggleKidsModeOff(tester);
      await kidsModeShouldBeOff(tester);
      await theActiveThemeShouldBeClassic(tester);
    });
    testWidgets(
      '''Selecting a kids theme while in kids mode applies immediately''',
      (tester) async {
        await kidsModeIsOn(tester);
        await iOpenTheThemePicker(tester);
        await iSelectTheBubblegumTheme(tester);
        await theActiveThemeShouldBeBubblegum(tester);
      },
    );
    testWidgets('''Kids mode persists across app restarts''', (tester) async {
      await kidsModeIsOnWithThemeJungle(tester);
      await iCloseAndRelaunchTheApp(tester);
      await kidsModeShouldBeOn(tester);
      await theActiveThemeShouldBeJungle(tester);
      await theBrightnessShouldBeSystem(tester);
    });
    testWidgets('''Theme and brightness change independently''', (
      tester,
    ) async {
      await theAppIsOnTheClassicThemeWithSystemBrightness(tester);
      await iSelectTheRoseGardenTheme(tester);
      await iSelectDarkBrightness(tester);
      await theActiveThemeShouldBeRoseGarden(tester);
      await theBrightnessShouldBeDark(tester);
    });
  });
}
