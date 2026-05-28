import 'package:flutter_test/flutter_test.dart';

Future<void> theThemePickerShouldShowKidsThemesSunshineJungleBubblegumSuperHero(
  WidgetTester tester,
) async {
  expect(find.text('Sunshine'), findsOneWidget);
  expect(find.text('Jungle'), findsOneWidget);
  expect(find.text('Bubblegum'), findsOneWidget);
  expect(find.text('Super Hero'), findsOneWidget);
}
