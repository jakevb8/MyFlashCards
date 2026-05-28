import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocs/analytics/analytics_bloc.dart';
import 'blocs/analytics/analytics_event.dart';
import 'blocs/deck/deck_bloc.dart';
import 'blocs/deck/deck_event.dart';
import 'blocs/deck_sharing/deck_sharing_bloc.dart';
import 'blocs/flashcard/flashcard_bloc.dart';
import 'blocs/import_export/import_export_bloc.dart';
import 'blocs/import_export/import_export_event.dart';
import 'blocs/theme/theme_bloc.dart';
import 'blocs/theme/theme_state.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'models/deck.dart';
import 'models/flashcard.dart';
import 'models/study_session.dart';
import 'repositories/flashcard_repository.dart';
import 'repositories/hive_deck_repository.dart';
import 'repositories/hive_flashcard_repository.dart';
import 'repositories/hive_study_session_repository.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/decks/deck_list_screen.dart';
import 'screens/backup/backup_screen.dart';
import 'screens/generate/ai_generate_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'core/notification_prefs_keys.dart';
import 'services/deck_import_export_service.dart';
import 'services/deck_sharing_service.dart';
import 'services/firebase_backup_service.dart';
import 'services/notification_service.dart';

// SharedPreferences key tracking when the last auto-backup ran.
// Stored locally so the 23-hour check works without a network round-trip.
const _kLastAutoBackupKey = 'auto_backup_last_at';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage
  await Hive.initFlutter();
  Hive.registerAdapter(DeckAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  Hive.registerAdapter(StudySessionAdapter());
  await HiveDeckRepository.init();
  await HiveFlashcardRepository.init();
  await HiveStudySessionRepository.init();

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
  late final AnalyticsBloc _analyticsBloc;
  late final ImportExportBloc _importExportBloc;
  late final DeckSharingBloc _deckSharingBloc;

  final _deckRepo = HiveDeckRepository();
  final _cardRepo = HiveFlashcardRepository();
  final _sessionRepo = HiveStudySessionRepository();
  final _backupService = FirebaseBackupService();
  final _sharingService = DeckSharingService();
  final _notificationService = NotificationService();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _themeBloc = ThemeBloc(initialState: widget.initialTheme);
    _deckBloc = DeckBloc(repository: _deckRepo)..add(LoadDecks());
    _flashcardBloc = FlashcardBloc(repository: _cardRepo);
    _analyticsBloc = AnalyticsBloc(sessionRepository: _sessionRepo)
      ..add(const LoadAnalytics());
    _importExportBloc = ImportExportBloc(
      deckRepository: _deckRepo,
      flashcardRepository: _cardRepo,
      service: DeckImportExportService(),
      sharingService: _sharingService,
    );
    _deckSharingBloc = DeckSharingBloc(service: _sharingService);
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
    // Initialise the notification plugin. Fire-and-forget — init failure is
    // non-fatal and will surface as a NotificationServiceException only when
    // the user tries to enable reminders.
    _notificationService.init();
    _maybeRescheduleReminder();
  }

  /// Wires up the AppLinks listener for deck-share deep links.
  ///
  /// Handles both cold-start (getInitialLink) and warm/hot-start (uriLinkStream)
  /// cases. Malformed or non-share links are silently ignored.
  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Cold start: app launched by tapping a link while not running.
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    // Warm/hot start: link tapped while the app is already running.
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {
        // Malformed links are silently ignored to avoid crashing the app.
      },
    );
  }

  /// Dispatches [ImportSharedDeckRequested] for myflashcards://deck/{shareId} links.
  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'myflashcards' || uri.host != 'deck') return;
    final shareId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    if (shareId != null && shareId.isNotEmpty) {
      _importExportBloc.add(ImportSharedDeckRequested(shareId));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    _themeBloc.close();
    _deckBloc.close();
    _flashcardBloc.close();
    _analyticsBloc.close();
    _importExportBloc.close();
    _deckSharingBloc.close();
    super.dispose();
  }

  /// Fires on every app resume. Triggers a silent backup and reschedules the
  /// daily reminder so the due-card count stays accurate after returning.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeAutoBackup();
      _maybeRescheduleReminder();
    }
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

  /// Reschedules the daily reminder with a fresh due-card count if reminders
  /// are enabled. Called on app start and every time the app resumes so the
  /// notification body stays accurate after the user studies or cards become due.
  Future<void> _maybeRescheduleReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(kReminderEnabledKey) ?? false;
    if (!enabled) return;
    final hour = prefs.getInt(kReminderHourKey) ?? 9;
    final minute = prefs.getInt(kReminderMinuteKey) ?? 0;
    final dueCount = await _cardRepo.countDueCards();
    try {
      await _notificationService.scheduleDailyReminder(
        time: TimeOfDay(hour: hour, minute: minute),
        dueCount: dueCount,
      );
    } on NotificationServiceException {
      // Best-effort on resume — silent fail so the app never blocks on a
      // notification error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _deckRepo),
        // Registered under both its concrete type (used by _shareViaLink and
        // other callers that need HiveFlashcardRepository-specific methods) and
        // the abstract interface (used by StudyScreen, deck tile stats, etc.).
        RepositoryProvider.value(value: _cardRepo),
        RepositoryProvider<FlashcardRepository>.value(value: _cardRepo),
        RepositoryProvider.value(value: _sessionRepo),
        RepositoryProvider.value(value: _notificationService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _themeBloc),
          BlocProvider.value(value: _deckBloc),
          BlocProvider.value(value: _flashcardBloc),
          BlocProvider.value(value: _analyticsBloc),
          BlocProvider.value(value: _importExportBloc),
          BlocProvider.value(value: _deckSharingBloc),
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
                '/analytics': (_) => const AnalyticsScreen(),
                '/backup': (_) => const BackupScreen(),
                '/generate': (_) => const AiGenerateScreen(),
                '/settings': (_) => const SettingsScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}
