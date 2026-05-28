import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theBrightnessShouldBeLight(WidgetTester tester) async {
  expect(testThemeBloc!.state.themeMode, ThemeMode.light);
}
