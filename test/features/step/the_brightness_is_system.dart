import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/theme/theme_bloc.dart';
import 'package:my_flash_cards/blocs/theme/theme_state.dart';
import '../helpers/test_helpers.dart';

Future<void> theBrightnessIsSystem(WidgetTester tester) async {
  resetTestState();
  testThemeBloc = ThemeBloc(
    initialState: const ThemeState(themeMode: ThemeMode.system),
  );
  await tester.pumpWidget(buildDeckListApp(themeBloc: testThemeBloc));
  await tester.pumpAndSettle();
}
