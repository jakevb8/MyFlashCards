import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/core/theme/app_theme.dart';
import '../helpers/test_helpers.dart';

Future<void> theActiveThemeShouldBeSunshine(WidgetTester tester) async {
  expect(testThemeBloc!.state.themeType, AppThemeType.sunshine);
}
