# MyFlashCards — Requirements Archive

Completed feature specs are moved here from `REQUIREMENTS_SPECS.md` after their commit is pushed.

## [FEAT-008] Backup V2 — completed 5e40f58

Incremental Firestore sync, `BackupMeta` + `BackupSchemaException` typed classes,
restore confirmation dialog with deck/card counts, "last backed up X ago" display,
silent daily auto-backup via `WidgetsBindingObserver`, and `schemaVersion` stamp
on every backed-up document.

Files changed: `firebase_backup_service.dart`, `backup_screen.dart`, `main.dart`,
`hive_flashcard_repository.dart`.
