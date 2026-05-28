import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iTapTheFlipIconInTheAppBar(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.flip_camera_android_outlined));
  await tester.pumpAndSettle();
}
