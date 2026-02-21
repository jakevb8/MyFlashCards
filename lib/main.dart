import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'blocs/deck/deck_bloc.dart';
import 'blocs/deck/deck_event.dart';
import 'blocs/flashcard/flashcard_bloc.dart';
import 'core/theme/app_theme.dart';
import 'models/deck.dart';
import 'models/flashcard.dart';
import 'repositories/hive_deck_repository.dart';
import 'repositories/hive_flashcard_repository.dart';
import 'screens/decks/deck_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage
  await Hive.initFlutter();
  Hive.registerAdapter(DeckAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  await HiveDeckRepository.init();
  await HiveFlashcardRepository.init();

  // NOTE: To enable Firebase backup, follow README.md setup steps,
  // then uncomment the line below and add your google-services.json /
  // GoogleService-Info.plist files to the respective platform folders.
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        child: MaterialApp(
          title: 'My Flash Cards',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          home: const DeckListScreen(),
        ),
      ),
    );
  }
}
