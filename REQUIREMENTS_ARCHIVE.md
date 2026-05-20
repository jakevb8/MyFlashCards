# MyFlashCards — Requirements Archive

Completed feature specs are moved here from `REQUIREMENTS_SPECS.md` after their commit is pushed.

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
