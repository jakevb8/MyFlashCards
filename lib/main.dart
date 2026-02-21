import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'blocs/deck/deck_bloc.dart';
import 'blocs/deck/deck_event.dart';
import 'blocs/flashcard/flashcard_bloc.dart';
import 'blocs/theme/theme_bloc.dart';
import 'blocs/theme/theme_state.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'models/deck.dart';
import 'models/flashcard.dart';
import 'repositories/hive_deck_repository.dart';
import 'repositories/hive_flashcard_repository.dart';
import 'screens/decks/deck_list_screen.dart';
import 'screens/backup/backup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage
  await Hive.initFlutter();
  Hive.registerAdapter(DeckAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  await HiveDeckRepository.init();
  await HiveFlashcardRepository.init();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyFlashCardsApp());
}

class MyFlashCardsApp extends StatelessWidget {
  const MyFlashCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => HiveDeckRepository()),
        RepositoryProvider(create: (_) => HiveFlashcardRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeBloc()),
          BlocProvider(
            create: (ctx) =>
                DeckBloc(repository: ctx.read<HiveDeckRepository>())
                  ..add(LoadDecks()),
          ),
          BlocProvider(
            create: (ctx) =>
                FlashcardBloc(repository: ctx.read<HiveFlashcardRepository>()),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'My Flash Cards',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(themeState.themeType),
              darkTheme: AppTheme.dark(themeState.themeType),
              themeMode: themeState.themeMode,
              home: const DeckListScreen(),
              routes: {
                '/backup': (_) => const BackupScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}
