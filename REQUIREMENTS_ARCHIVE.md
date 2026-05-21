# MyFlashCards — Requirements Archive

Completed feature specs are moved here from `REQUIREMENTS_SPECS.md` after their commit is pushed.

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
