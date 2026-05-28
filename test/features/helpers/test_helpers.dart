// test_helpers.dart
//
// Shared infrastructure for BDD feature tests. Every step file imports this
// module and reads/writes the module-level variables to share state across
// steps within the same testWidgets block. Flutter widget tests are sequential
// so module-level state is safe here.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_flash_cards/blocs/analytics/analytics_bloc.dart';
import 'package:my_flash_cards/blocs/analytics/analytics_event.dart';
import 'package:my_flash_cards/blocs/deck/deck_bloc.dart';
import 'package:my_flash_cards/blocs/deck/deck_event.dart';
import 'package:my_flash_cards/blocs/deck_sharing/deck_sharing_bloc.dart';
import 'package:my_flash_cards/blocs/flashcard/flashcard_bloc.dart';
import 'package:my_flash_cards/blocs/flashcard/flashcard_event.dart';
import 'package:my_flash_cards/blocs/import_export/import_export_bloc.dart';
import 'package:my_flash_cards/blocs/theme/theme_bloc.dart';
import 'package:my_flash_cards/blocs/theme/theme_state.dart';
import 'package:my_flash_cards/core/theme/app_theme.dart';
import 'package:my_flash_cards/models/deck.dart';
import 'package:my_flash_cards/models/flashcard.dart';
import 'package:my_flash_cards/models/study_mode.dart';
import 'package:my_flash_cards/models/study_session.dart';
import 'package:my_flash_cards/repositories/deck_repository.dart';
import 'package:my_flash_cards/repositories/flashcard_repository.dart';
import 'package:my_flash_cards/repositories/study_session_repository.dart';
import 'package:my_flash_cards/screens/cards/flashcard_list_screen.dart';
import 'package:my_flash_cards/screens/decks/deck_list_screen.dart';
import 'package:my_flash_cards/screens/study/study_screen.dart';
import 'package:my_flash_cards/services/deck_import_export_service.dart';
import 'package:my_flash_cards/services/deck_sharing_service.dart';
import 'package:my_flash_cards/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Module-level shared state ─────────────────────────────────────────────────
// Each "Given" setup step should reset these before use.

FakeDeckRepository testDeckRepo = FakeDeckRepository();
FakeFlashcardRepository testCardRepo = FakeFlashcardRepository();
FakeStudySessionRepository testSessionRepo = FakeStudySessionRepository();

// Blocs exposed so assertion steps can inspect state directly.
ThemeBloc? testThemeBloc;
DeckBloc? testDeckBloc;
FlashcardBloc? testCardBloc;

// Current deck/cards used by multi-step study/flashcard tests.
Deck? testCurrentDeck;
List<Flashcard> testCurrentCards = [];

// Expected IDs for "ID preserved" tests.
String? testExpectedDeckId;
String? testExpectedCardId;
String? testExpectedCardDeckId;

// ── Fake repository implementations ──────────────────────────────────────────

class FakeDeckRepository implements DeckRepository {
  final List<Deck> _store;
  FakeDeckRepository([List<Deck>? initial]) : _store = [...(initial ?? [])];

  @override
  Future<List<Deck>> getDecks() async => List.from(_store);

  @override
  Future<Deck> getDeck(String id) async => _store.firstWhere((d) => d.id == id);

  @override
  Future<void> addDeck(Deck deck) async => _store.add(deck);

  @override
  Future<void> updateDeck(Deck deck) async {
    final idx = _store.indexWhere((d) => d.id == deck.id);
    if (idx >= 0) _store[idx] = deck;
  }

  @override
  Future<void> deleteDeck(String id) async =>
      _store.removeWhere((d) => d.id == id);

  List<Deck> get all => List.unmodifiable(_store);
}

class FakeFlashcardRepository implements FlashcardRepository {
  final List<Flashcard> _store;
  FakeFlashcardRepository([List<Flashcard>? initial])
    : _store = [...(initial ?? [])];

  @override
  Future<List<Flashcard>> getFlashcards(String deckId) async =>
      _store.where((c) => c.deckId == deckId).toList();

  @override
  Future<Flashcard> getFlashcard(String id) async =>
      _store.firstWhere((c) => c.id == id);

  @override
  Future<void> addFlashcard(Flashcard flashcard) async => _store.add(flashcard);

  @override
  Future<void> updateFlashcard(Flashcard flashcard) async {
    final idx = _store.indexWhere((c) => c.id == flashcard.id);
    if (idx >= 0) {
      _store[idx] = flashcard;
    } else {
      _store.add(flashcard);
    }
  }

  @override
  Future<void> deleteFlashcard(String id) async =>
      _store.removeWhere((c) => c.id == id);

  @override
  Future<int> countDueCards() async {
    final now = DateTime.now();
    return _store
        .where(
          (c) =>
              !c.archived &&
              (c.nextReviewAt == null || !c.nextReviewAt!.isAfter(now)),
        )
        .length;
  }

  List<Flashcard> get all => List.unmodifiable(_store);
}

/// No-op notification service for widget tests — never actually schedules
/// anything so tests are not coupled to the notification plugin.
class FakeNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required int dueCount,
  }) async {}

  @override
  Future<void> cancelDailyReminder() async {}
}

class FakeStudySessionRepository implements StudySessionRepository {
  final List<StudySession> _store = [];

  @override
  Future<List<StudySession>> getSessions() async => List.from(_store);

  @override
  Future<void> addSession(StudySession session) async => _store.add(session);

  @override
  Future<void> clearAll() async => _store.clear();
}

// ── Factory helpers ───────────────────────────────────────────────────────────

final _baseDate = DateTime(2026, 1, 1);
int _deckCounter = 0;
int _cardCounter = 0;

Deck makeDeck({
  String? id,
  String name = 'Test Deck',
  String description = '',
  List<String> tags = const [],
}) => Deck(
  id: id ?? 'deck-${++_deckCounter}',
  name: name,
  description: description,
  tags: tags,
  createdAt: _baseDate,
  updatedAt: _baseDate,
);

Flashcard makeCard({
  String? id,
  required String deckId,
  String front = 'Question',
  String back = 'Answer',
  int starCount = 0,
  bool archived = false,
  // null = never scheduled (always due); future = not yet due
  DateTime? nextReviewAt,
  double? easeFactor,
  int? intervalDays,
  int? repetitions,
}) => Flashcard(
  id: id ?? 'card-${++_cardCounter}',
  deckId: deckId,
  front: front,
  back: back,
  createdAt: _baseDate,
  updatedAt: _baseDate,
  starCount: starCount,
  archived: archived,
  nextReviewAt: nextReviewAt,
  easeFactor: easeFactor,
  intervalDays: intervalDays,
  repetitions: repetitions,
);

// ── Widget builders ───────────────────────────────────────────────────────────

/// Builds a full app with [DeckListScreen] as home.
/// Stores references to created blocs in the module-level [testDeckBloc] and
/// [testThemeBloc] so assertion steps can inspect state.
Widget buildDeckListApp({
  FakeDeckRepository? deckRepo,
  FakeFlashcardRepository? cardRepo,
  ThemeBloc? themeBloc,
}) {
  deckRepo ??= testDeckRepo;
  cardRepo ??= testCardRepo;

  final bloc = DeckBloc(repository: deckRepo)..add(LoadDecks());
  testDeckBloc = bloc;

  final cardBloc = FlashcardBloc(repository: cardRepo);
  testCardBloc = cardBloc;

  final analyticsBloc = AnalyticsBloc(sessionRepository: testSessionRepo)
    ..add(const LoadAnalytics());

  final importExportBloc = ImportExportBloc(
    deckRepository: deckRepo,
    flashcardRepository: cardRepo,
    service: DeckImportExportService(),
    sharingService: DeckSharingService(),
  );

  final sharingBloc = DeckSharingBloc(service: DeckSharingService());

  final tBloc = themeBloc ?? ThemeBloc();
  testThemeBloc = tBloc;

  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeBloc>.value(value: tBloc),
      BlocProvider<DeckBloc>.value(value: bloc),
      BlocProvider<FlashcardBloc>.value(value: cardBloc),
      BlocProvider<AnalyticsBloc>.value(value: analyticsBloc),
      BlocProvider<ImportExportBloc>.value(value: importExportBloc),
      BlocProvider<DeckSharingBloc>.value(value: sharingBloc),
    ],
    child: BlocBuilder<ThemeBloc, ThemeState>(
      bloc: tBloc,
      builder: (_, themeState) => MaterialApp(
        theme: AppTheme.light(themeState.themeType),
        darkTheme: AppTheme.dark(themeState.themeType),
        themeMode: themeState.themeMode,
        home: const DeckListScreen(),
        routes: {
          '/settings': (_) =>
              const Scaffold(body: Center(child: Text('Settings'))),
        },
      ),
    ),
  );
}

/// Builds an app with [FlashcardListScreen] as home for the given deck.
Widget buildFlashcardListApp({
  required Deck deck,
  required FakeFlashcardRepository cardRepo,
}) {
  final cardBloc = FlashcardBloc(repository: cardRepo);
  testCardBloc = cardBloc;

  final importExportBloc = ImportExportBloc(
    deckRepository: FakeDeckRepository([deck]),
    flashcardRepository: cardRepo,
    service: DeckImportExportService(),
    sharingService: DeckSharingService(),
  );

  final sharingBloc = DeckSharingBloc(service: DeckSharingService());

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<FlashcardRepository>.value(value: cardRepo),
      RepositoryProvider<StudySessionRepository>.value(value: testSessionRepo),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
        BlocProvider<FlashcardBloc>.value(value: cardBloc),
        BlocProvider<AnalyticsBloc>(
          create: (_) =>
              AnalyticsBloc(sessionRepository: testSessionRepo)
                ..add(const LoadAnalytics()),
        ),
        BlocProvider<ImportExportBloc>.value(value: importExportBloc),
        BlocProvider<DeckSharingBloc>.value(value: sharingBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: FlashcardListScreen(deck: deck),
      ),
    ),
  );
}

/// Builds an app with [StudyScreen] as home, providing repos via
/// [RepositoryProvider] so [StudyScreen] can create its own [StudyBloc].
Widget buildStudyApp({
  required Deck deck,
  required List<Flashcard> cards,
  FakeFlashcardRepository? cardRepo,
  FakeStudySessionRepository? sessionRepo,
  bool randomize = false,
  bool flipped = false,
  StudyMode mode = StudyMode.flashcard,
}) {
  final cr = cardRepo ?? FakeFlashcardRepository(cards);
  final sr = sessionRepo ?? testSessionRepo;

  final cardBloc = FlashcardBloc(repository: cr)..add(LoadFlashcards(deck.id));
  testCardBloc = cardBloc;

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<FlashcardRepository>.value(value: cr),
      RepositoryProvider<StudySessionRepository>.value(value: sr),
      // FakeNotificationService so the post-session reschedule listener works
      // without requiring the real notification plugin in widget tests.
      RepositoryProvider<NotificationService>.value(
        value: FakeNotificationService(),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
        BlocProvider<FlashcardBloc>.value(value: cardBloc),
        BlocProvider<AnalyticsBloc>(
          create: (_) =>
              AnalyticsBloc(sessionRepository: sr)..add(const LoadAnalytics()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: StudyScreen(
          deck: deck,
          flashcards: cards,
          randomize: randomize,
          flipped: flipped,
          mode: mode,
        ),
      ),
    ),
  );
}

// ── Convenience: reset shared state before each test ─────────────────────────

void resetTestState() {
  testDeckRepo = FakeDeckRepository();
  testCardRepo = FakeFlashcardRepository();
  testSessionRepo = FakeStudySessionRepository();
  testThemeBloc = null;
  testDeckBloc = null;
  testCardBloc = null;
  testCurrentDeck = null;
  testCurrentCards = [];
  testExpectedDeckId = null;
  testExpectedCardId = null;
  testExpectedCardDeckId = null;
  SharedPreferences.setMockInitialValues({});
}
