import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/theme/theme_bloc.dart';
import '../helpers/test_helpers.dart';

Future<void> theAppIsOnTheClassicTheme(WidgetTester tester) async {
  resetTestState();
  testThemeBloc = ThemeBloc();
  await tester.pumpWidget(buildDeckListApp(themeBloc: testThemeBloc));
  await tester.pumpAndSettle();
}
