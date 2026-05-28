import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/theme/theme_bloc.dart';
import 'package:my_flash_cards/blocs/theme/theme_state.dart';
import 'package:my_flash_cards/core/theme/app_theme.dart';
import '../helpers/test_helpers.dart';

Future<void> kidsModeIsOn(WidgetTester tester) async {
  resetTestState();
  testThemeBloc = ThemeBloc(
    initialState: const ThemeState(
      isKidsMode: true,
      themeType: AppThemeType.sunshine,
    ),
  );
  await tester.pumpWidget(buildDeckListApp(themeBloc: testThemeBloc));
  await tester.pumpAndSettle();
}
