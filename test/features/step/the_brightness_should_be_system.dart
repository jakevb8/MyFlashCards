import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theBrightnessShouldBeSystem(WidgetTester tester) async {
  expect(testThemeBloc!.state.themeMode, equals(ThemeMode.system));
}
