# MyFlashCards — Requirements Archive

Completed feature specs are moved here from `REQUIREMENTS_SPECS.md` after their commit is pushed.

## [FEAT-005] Multiple Study Modes — completed 6988a83

StudyMode enum (flashcard | multipleChoice | typeAnswer). Mode picker bottom sheet
(StudyModePickerSheet) with shuffle/flip options replaces the three separate study
buttons. StudyBloc generates MC choices (correct + up to 3 distractors from full deck)
on start and every card advance. TypeAnswer view checks case-insensitive match;
tolerant mode accepts answers within 2 edit-distance. Both modes auto-dispatch RateCard.

---

## [FEAT-004] Study Analytics & Streaks — completed a216e50

StudySession model (Hive typeId=2) persists date/cardsReviewed/correctCount per session.
AnalyticsBloc computes streak (consecutive days from today or yesterday), accuracy (correctCount/total),
and last7Days DailyCounts for bar chart. Analytics screen shows streak card, 7-day bar chart (no external
charting dep), accuracy %, and total cards reviewed. Streak banner on deck list links to analytics screen.
BlocListener in StudyScreen fires LoadAnalytics when StudyComplete.

---

## [FEAT-003] Spaced Repetition (SM-2) — completed 9921f5a

SM-2 algorithm replaces random-shuffle study mode. `SpacedRepetitionService.schedule(card, 0–5)`
returns an updated card copy with new `easeFactor`, `intervalDays`, `repetitions`, `nextReviewAt`.
EF clamped to min 1.3; interval ladder: 1 → 6 → `round(interval * EF)`; failure resets to 1 day.
`StudyBloc` now requires `FlashcardRepository` and `SpacedRepetitionService` (injectable);
filters session to due cards on start; `RateCard` event persists SM-2 schedule via repository
then auto-advances. Study screen shows Again/Hard/Good/Easy buttons after card flip; "You're all
caught up!" empty state when no cards are due. Flashcard model gains 4 nullable HiveFields (8–11);
old Hive records with missing fields read as null and treated as new cards.

Files changed: `flashcard.dart`, `flashcard.g.dart`, `spaced_repetition_service.dart`,
`study_bloc.dart`, `study_event.dart`, `study_screen.dart`, `study_bloc_test.dart`,
`spaced_repetition_service_test.dart`, `feat_003_spaced_repetition.feature`.

## [FEAT-002] Gemini API Key Settings — completed 4835ab1

`GeminiKeyService` wraps `FlutterSecureStorage` (injectable for tests). `SettingsBloc`
with `GeminiKeyLoaded/Changed/Saved/Cleared` events; sentinel `copyWith` pattern to
clear `errorMessage` explicitly. 4-step `GeminiKeyWalkthrough` PageView with
`url_launcher` to AI Studio. Settings screen gains AI Settings section (first) with
masked key display and bottom sheet editor; BLoC survives sheet open/close via
`BlocProvider.value` at screen level. `AiGenerateScreen` drops `--dart-define`
dependency; reads key from `GeminiKeyService` in `initState`; gates generation with
actionable SnackBar. `flutter_secure_storage ^9.2.4` added.

Files changed: `gemini_key_service.dart`, `settings_bloc/event/state.dart`,
`gemini_key_walkthrough.dart`, `settings_screen.dart`, `ai_generate_screen.dart`,
`pubspec.yaml`.

## [FEAT-001] Google Sign-In — completed 172c4c9

`signInWithGoogle()` added to `FirebaseBackupService` — native Google account picker,
exchanges credential via `GoogleAuthProvider.credential`, throws typed Exception on
dismissal. `signOut()` updated to sign out Google first then Firebase (order matters).
BackupScreen now shows Google card (recommended) above GitHub card. iOS `Info.plist`
`CFBundleURLTypes` entry added with REVERSED_CLIENT_ID placeholder.

Files changed: `firebase_backup_service.dart`, `backup_screen.dart`,
`ios/Runner/Info.plist`, `pubspec.yaml`.

## [FEAT-008] Backup V2 — completed 5e40f58

Incremental Firestore sync, `BackupMeta` + `BackupSchemaException` typed classes,
restore confirmation dialog with deck/card counts, "last backed up X ago" display,
silent daily auto-backup via `WidgetsBindingObserver`, and `schemaVersion` stamp
on every backed-up document.

Files changed: `firebase_backup_service.dart`, `backup_screen.dart`, `main.dart`,
`hive_flashcard_repository.dart`.

## [FEAT-009] Privacy & Account Management — completed 67e16bd

`AccountDeletionService` deletes all Firestore subcollections (decks, flashcards, _meta)
in batches, calls `currentUser!.delete()`, clears Hive + SharedPreferences; translates
`requires-recent-login` to typed `ReauthRequiredException`. `SettingsScreen` with Account
(sign out, delete) and About (privacy policy, version) sections. `PrivacyPolicyScreen`
static scrollable content with Play Store hosted-URL TODO. Settings icon added to
DeckListScreen AppBar. Step 3 (remove anonymous auth) deferred to FEAT-001.

Files changed: `account_deletion_service.dart`, `settings_screen.dart`,
`privacy_policy_screen.dart`, `deck_list_screen.dart`, `main.dart`, `pubspec.yaml`.

---

## [FEAT-006] Deck Import / Export

**Goal:** Let users export a deck as a CSV or JSON file and import decks from the same formats.

**Why:** Enables users to create cards in spreadsheets, share decks with friends, or back up data independently of Firebase.

**Scope:**
- Export: `DeckImportExportService` serializes deck + cards to CSV or JSON; writes to temp dir; invokes platform share sheet via `share_plus`
- Import: parse CSV/JSON via `file_picker` (`withData: true`); validate schema; create deck + cards in Hive
- Handle duplicates: detect name clash, show Replace / Merge / Cancel dialog
- Merge: keep existing deck record, add only cards with new IDs (rewrite `deckId`)
- Replace: delete old deck + all its cards, then import fresh

**Commit:** 688b64b

---

## [FEAT-007] Deck Sharing via Link — completed b8ac09a

`DeckSharingService` publishes deck+cards JSON to `/shared_decks/{shareId}` (Firestore)
with a 7-day TTL (enforced at read time). Deep-link format: `myflashcards://deck/{shareId}`.
`DeckSharingBloc` manages the sender state machine. Share action added to the deck tile
swipe menu (`DeckListScreen`) and to the flashcard list AppBar `PopupMenuButton`.
`ShareDeckDialog` bottom sheet shows a progress indicator, copyable link, and system
share button. `AppLinks` listener in `main.dart` handles both cold-start and warm-start
deep links, dispatching `ImportSharedDeckRequested` to `ImportExportBloc` (which reuses
the existing duplicate-detection state machine). SM-2 progress stripped on import;
fresh UUIDs assigned so receiver's copy is independent of sender's.

Files changed: `deck_sharing_service.dart` (new), `deck_sharing_bloc/` (new),
`share_deck_dialog.dart` (new), `deck_import_export_service.dart`, `import_export_bloc.dart`,
`import_export_event.dart`, `deck_list_screen.dart`, `flashcard_list_screen.dart`,
`main.dart`, `AndroidManifest.xml`, `Info.plist`, `firestore.rules`,
`feat_007_deck_sharing.feature` (new), `widget_test.dart`.

---

## [FEAT-010] Daily Review Reminders

**Priority:** P0
**Status:** completed
**Commit:** 67bdacb

### Goal
Surface a local push notification each day when the user has cards due for review.

### Acceptance Criteria (all met)
- `flutter_local_notifications` + `timezone` packages added.
- Settings screen has a "Daily reminder" SwitchListTile and a time picker.
- Notification body: "You have N cards due today" (computed from local Hive).
- After completing a study session the notification is rescheduled.
- Works on iOS and Android; permission requested on first enable.
- Preference stored in `shared_preferences` via `kReminderEnabledKey`, `kReminderHourKey`, `kReminderMinuteKey`.

### Implementation Notes
`NotificationService` wraps `FlutterLocalNotificationsPlugin` with timezone-aware
`zonedSchedule`. `SettingsBloc` gains `NotificationPrefsLoaded`, `ReminderToggled`,
`ReminderTimeChanged` events. `FlashcardRepository.countDueCards()` added to interface.
`main.dart` reschedules on app resume via `_maybeRescheduleReminder()`.

---

## [FEAT-011] Per-Deck Progress Dashboard

**Priority:** P1
**Status:** completed
**Commit:** 53b5305

### Goal
Show at-a-glance progress stats on each deck tile: due-today count, active count, mastered (archived) count.

### Implementation Notes
`_DeckTile` converted to `StatefulWidget`; `_statsFuture` loads cards via `FlashcardRepository.getFlashcards(deckId)` in `initState()` (once per tile lifecycle, not per rebuild). `_DeckStats.fromCards()` computes three metrics in a single pass. `_DeckProgressRow` renders stat chips with colour-coded icons. Zero-due decks show "All caught up" chip instead of the due count. Also fixed `main.dart` to register `_cardRepo` under both `HiveFlashcardRepository` and `FlashcardRepository` so context.read<FlashcardRepository>() works in production.

## [FEAT-012] Study Goals & Milestones — completed d817636

**Priority:** P1

### Goal
Let users set a daily card-study goal and celebrate milestone moments to create a stronger motivational feedback loop.

### Implementation Notes
`dailyGoal` (default 10) added to `SettingsState` and persisted via `kDailyGoalKey` in SharedPreferences. `_showGoalDialog` in settings_screen.dart lets the user update the goal. `_DailyGoalBanner` StatefulWidget added to deck_list_screen.dart reads goal + `cardsReviewedToday` from `AnalyticsLoaded` to show a LinearProgressIndicator. `cardsReviewedToday` computed in `AnalyticsBloc` by counting sessions from today. Milestones tracked via six SharedPreferences boolean flags in `notification_prefs_keys.dart`. `_CompletionView` converted to `StatefulWidget` with `ConfettiController`; `_checkMilestones()` in `addPostFrameCallback` reads analytics state + flags, fires confetti on the first newly-hit milestone, then marks it seen. `confetti: ^0.7.0` package added to pubspec.

## [FEAT-013] Card-Level Edit During Study — completed ffa9520

**Priority:** P1

### Goal
Allow users to edit the current flashcard inline during a study session without losing their place.

### Implementation Notes
New `EditCardInSession(Flashcard updated)` event added to `study_event.dart`. Handler `_onEditCardInSession` in `StudyBloc` persists via repository, patches `_originalCards` and `_allCardsFlipped` (MC distractor pool), re-applies flip transform for the display copy, then emits updated `StudyInProgress`. Edit icon (`Icons.edit_outlined`) added to `_StudyView` AppBar inside a `BlocBuilder` — visible only during `StudyInProgress`. Tapping opens `_EditCardSheet` modal bottom sheet (un-applies flip for correct canonical pre-fill). Sheet has two `TextFormField`s (Front/Back) with validation, Cancel/Save row. All SM-2 fields are preserved via `copyWith`; only `front`, `back`, `updatedAt` are changed.

## [FEAT-014] AI Card Regeneration — completed 4788f1d

**Priority:** P2

### Goal
Let users regenerate a single AI-generated flashcard's front/back to be clearer and more concise using Gemini.

### Implementation Notes
`RegenerateFlashcard(String id)` event added to `flashcard_event.dart`. `FlashcardLoaded` state extended with `regeneratingIds: Set<String>` (per-card spinner) and `regenerateError: String?` (one-shot error for SnackBar via `BlocListener`). `GeminiDirectService.regenerateCard(front, back)` added to `ai_deck_service.dart` — reuses `_generate()` helper with a targeted prompt. `GeminiKeyService` injected into `FlashcardBloc` (optional, defaults to `GeminiKeyService()`). Handler `_onRegenerateFlashcard` emits spinner → reads key → calls Gemini → persists via repository → reloads. `FlashcardListScreen` checks `GeminiKeyService().hasKey()` in `initState` and passes `hasGeminiKey` + `isRegenerating` to `_CardTile`. `_CardTile` shows a "Rewrite" `SlidableAction` (only when key set) and a `Positioned.fill` spinner overlay when `isRegenerating`. Swipe hint banner text updates to reflect AI capability.
