import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/theme/theme_bloc.dart';
import '../helpers/test_helpers.dart';

// Opens the theme picker so subsequent select steps can interact with it
// without a separate i_open_the_theme_picker step in the scenario.
Future<void> theAppIsOnTheClassicThemeWithSystemBrightness(
  WidgetTester tester,
) async {
  resetTestState();
  testThemeBloc = ThemeBloc();
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  await tester.pumpWidget(buildDeckListApp(themeBloc: testThemeBloc));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.palette_outlined));
  await tester.pumpAndSettle();
}
