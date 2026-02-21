import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/theme/theme_bloc.dart';
import 'package:my_flash_cards/core/theme/app_theme.dart';
import 'package:my_flash_cards/screens/decks/deck_list_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_flash_cards/blocs/deck/deck_bloc.dart';
import 'package:my_flash_cards/blocs/deck/deck_event.dart';
import 'package:my_flash_cards/blocs/flashcard/flashcard_bloc.dart';
import 'package:my_flash_cards/repositories/deck_repository.dart';
import 'package:my_flash_cards/repositories/flashcard_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDeckRepository extends Mock implements DeckRepository {}

class MockFlashcardRepository extends Mock implements FlashcardRepository {}

Widget _buildApp({required DeckBloc deckBloc}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
      BlocProvider<DeckBloc>.value(value: deckBloc),
      BlocProvider<FlashcardBloc>(
        create: (_) => FlashcardBloc(repository: MockFlashcardRepository()),
      ),
    ],
    child: BlocBuilder<ThemeBloc, dynamic>(
      builder: (context, state) =>
          MaterialApp(theme: AppTheme.light(), home: const DeckListScreen()),
    ),
  );
}

void main() {
  late MockDeckRepository deckRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    deckRepo = MockDeckRepository();
    when(() => deckRepo.getDecks()).thenAnswer((_) async => []);
  });

  testWidgets('DeckListScreen shows app bar title', (tester) async {
    final deckBloc = DeckBloc(repository: deckRepo)..add(LoadDecks());

    await tester.pumpWidget(_buildApp(deckBloc: deckBloc));
    await tester.pumpAndSettle();

    expect(find.text('My Flashcard Decks'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
