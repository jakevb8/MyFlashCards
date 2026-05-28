import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/theme/theme_bloc.dart';
import '../helpers/test_helpers.dart';

// Simulates an app restart by loading theme from SharedPreferences and
// rebuilding the widget tree with the persisted state.
Future<void> iCloseAndRelaunchTheApp(WidgetTester tester) async {
  final savedTheme = await ThemeBloc.loadSaved();
  testThemeBloc = ThemeBloc(initialState: savedTheme);
  await tester.pumpWidget(buildDeckListApp(themeBloc: testThemeBloc));
  await tester.pumpAndSettle();
}
