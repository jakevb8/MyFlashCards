import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theBrightnessShouldBeDark(WidgetTester tester) async {
  expect(testThemeBloc!.state.themeMode, ThemeMode.dark);
}
