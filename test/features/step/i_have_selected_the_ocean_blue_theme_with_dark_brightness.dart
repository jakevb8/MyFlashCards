import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/theme/theme_bloc.dart';
import 'package:my_flash_cards/blocs/theme/theme_state.dart';
import 'package:my_flash_cards/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.dart';

Future<void> iHaveSelectedTheOceanBlueThemeWithDarkBrightness(
  WidgetTester tester,
) async {
  resetTestState();
  // Store theme in SharedPreferences so i_close_and_relaunch_the_app loads it.
  SharedPreferences.setMockInitialValues({
    'theme_type': AppThemeType.oceanBlue.index,
    'theme_mode': ThemeMode.dark.index,
    'kids_mode': false,
  });
  testThemeBloc = ThemeBloc(
    initialState: const ThemeState(
      themeType: AppThemeType.oceanBlue,
      themeMode: ThemeMode.dark,
    ),
  );
  await tester.pumpWidget(buildDeckListApp(themeBloc: testThemeBloc));
  await tester.pumpAndSettle();
}
