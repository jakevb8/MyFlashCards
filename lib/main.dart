import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'screens/generate/ai_generate_screen.dart';
import 'services/firebase_backup_service.dart';

// SharedPreferences key tracking when the last auto-backup ran.
// Stored locally so the 23-hour check works without a network round-trip.
const _kLastAutoBackupKey = 'auto_backup_last_at';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage
  await Hive.initFlutter();
  Hive.registerAdapter(DeckAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  await HiveDeckRepository.init();
  await HiveFlashcardRepository.init();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final savedTheme = await ThemeBloc.loadSaved();

  runApp(MyFlashCardsApp(initialTheme: savedTheme));
}

class MyFlashCardsApp extends StatefulWidget {
  final ThemeState initialTheme;
  const MyFlashCardsApp({super.key, required this.initialTheme});

  @override
  State<MyFlashCardsApp> createState() => _MyFlashCardsAppState();
}

class _MyFlashCardsAppState extends State<MyFlashCardsApp>
    with WidgetsBindingObserver {
  late final ThemeBloc _themeBloc;
  late final DeckBloc _deckBloc;
  late final FlashcardBloc _flashcardBloc;

  final _deckRepo = HiveDeckRepository();
  final _cardRepo = HiveFlashcardRepository();
  final _backupService = FirebaseBackupService();

  @override
  void initState() {
    super.initState();
    _themeBloc = ThemeBloc(initialState: widget.initialTheme);
    _deckBloc = DeckBloc(repository: _deckRepo)..add(LoadDecks());
    _flashcardBloc = FlashcardBloc(repository: _cardRepo);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeBloc.close();
    _deckBloc.close();
    _flashcardBloc.close();
    super.dispose();
  }

  /// Fires on every app resume. Triggers a silent backup if the user is signed
  /// in (non-anonymous) and the last auto-backup was more than 23 hours ago.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _maybeAutoBackup();
  }

  Future<void> _maybeAutoBackup() async {
    if (!_backupService.isSignedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final lastRaw = prefs.getString(_kLastAutoBackupKey);
    if (lastRaw != null) {
      final lastAt = DateTime.parse(lastRaw);
      if (DateTime.now().difference(lastAt).inHours < 23) return;
    }

    try {
      final decks = await _deckRepo.getDecks();
      final cards = await _cardRepo.getAllFlashcards();
      final theme = _themeBloc.state;

      await _backupService.backupAll(
        decks: decks,
        cards: cards,
        themeTypeIndex: theme.themeType.index,
        themeModeIndex: theme.themeMode.index,
        isKidsMode: theme.isKidsMode,
      );

      await prefs.setString(
        _kLastAutoBackupKey,
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {
      // Auto-backup is best-effort — failures are shown via the BackupScreen,
      // not surfaced here to avoid interrupting the user on app open.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _deckRepo),
        RepositoryProvider.value(value: _cardRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _themeBloc),
          BlocProvider.value(value: _deckBloc),
          BlocProvider.value(value: _flashcardBloc),
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
                '/generate': (_) => const AiGenerateScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}
