import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/study/study_bloc.dart';
import 'package:my_flash_cards/blocs/study/study_event.dart';
import 'package:my_flash_cards/screens/study/study_screen.dart';

Future<void> iTapNext(WidgetTester tester) async {
  // Read StudyBloc from the Scaffold (inside the BlocProvider) rather than
  // from StudyScreen itself, which is above the BlocProvider in the tree.
  final ctx = tester.element(
    find
        .descendant(
          of: find.byType(StudyScreen),
          matching: find.byType(Scaffold),
        )
        .first,
  );
  ctx.read<StudyBloc>().add(NextCard());
  await tester.pumpAndSettle();
}
