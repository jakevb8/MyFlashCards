import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> kidsModeShouldBeOn(WidgetTester tester) async {
  expect(testThemeBloc!.state.isKidsMode, isTrue);
}
