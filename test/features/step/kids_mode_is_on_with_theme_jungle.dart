import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/theme/theme_bloc.dart';
import 'package:my_flash_cards/blocs/theme/theme_state.dart';
import 'package:my_flash_cards/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.dart';

Future<void> kidsModeIsOnWithThemeJungle(WidgetTester tester) async {
  resetTestState();
  // Persist to SharedPreferences so i_close_and_relaunch_the_app can reload it.
  SharedPreferences.setMockInitialValues({
    'theme_type': AppThemeType.jungle.index,
    'theme_mode': ThemeMode.system.index,
    'kids_mode': true,
  });
  testThemeBloc = ThemeBloc(
    initialState: const ThemeState(
      isKidsMode: true,
      themeType: AppThemeType.jungle,
    ),
  );
  await tester.pumpWidget(buildDeckListApp(themeBloc: testThemeBloc));
  await tester.pumpAndSettle();
}
