import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/study/study_bloc.dart';
import 'package:my_flash_cards/blocs/study/study_event.dart';
import 'package:my_flash_cards/blocs/study/study_state.dart';
import 'package:my_flash_cards/screens/study/study_screen.dart';

Future<void> iRateEachCard(WidgetTester tester) async {
  while (true) {
    final scaffoldCtx = tester.element(
      find
          .descendant(
            of: find.byType(StudyScreen),
            matching: find.byType(Scaffold),
          )
          .first,
    );
    final state = scaffoldCtx.read<StudyBloc>().state;
    if (state is! StudyInProgress) break;
    scaffoldCtx.read<StudyBloc>().add(FlipCard());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
  }
}
