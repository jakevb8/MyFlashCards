<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# MyFlashCards — Copilot Instructions

## Project Overview
This is a **Flutter cross-platform flashcard application** using spec-driven development (SDD/TDD/BDD).

## Architecture
- **State Management**: flutter_bloc (BLoC pattern)
- **Local Storage**: Hive CE (via `hive_ce_flutter`)
- **Cloud Backup**: Firebase Auth + Cloud Firestore (free tier)
- **Testing**: flutter_test + bloc_test + mocktail + bdd_widget_test

## Folder Structure
```
lib/
  models/          # Data models (Deck, Flashcard) with Hive adapters
  repositories/    # Abstract interfaces + Hive implementations
  blocs/           # BLoC state management (deck/, flashcard/, study/, auth/)
  screens/         # UI screens (decks/, cards/, study/, auth/)
  widgets/         # Shared reusable widgets
  services/        # FirebaseBackupService
  core/theme/      # AppTheme (light + dark, Material 3)
test/
  unit/            # Unit tests for models, blocs, repositories
  widget/          # Widget tests
  features/        # BDD .feature files (Gherkin specs)
```

## ⚠️ MANDATORY: Spec-First, Spec-Last Rule
**Every task MUST follow this checklist — do not skip any step:**
1. **Write or update the `.feature` file FIRST** — before touching any `lib/` code
2. Run it — confirm it fails (Red)
3. Implement the minimum code to make it pass (Green)
4. Refactor
5. **Update the `.feature` file AGAIN at the end** — add/edit scenarios to match the final implemented behaviour, including edge cases and bug fixes
6. **Run `flutter test`** — all tests must pass before marking complete
7. **Commit message must list which `.feature` files were changed**

> If a task changes user-visible behaviour and no `.feature` file was updated, the task is **incomplete**.

## Code Conventions
- All models must implement `Equatable` and have `toJson`/`fromJson`
- All BLoC events/states must extend `Equatable`
- Repository interfaces live in `lib/repositories/` as abstract classes
- Hive adapters are hand-written in `.g.dart` files (typeId 0 = Deck, 1 = Flashcard)
- Always use `context.read<BlocType>()` for one-off calls and `BlocBuilder` for UI
- Use Material 3 components and `AppTheme.light` / `AppTheme.dark`
- **Always declare direct imports explicitly in `pubspec.yaml`** — do not rely on a package being transitively re-exported by another (e.g. `hive_ce` must be listed even though `hive_ce_flutter` includes it). The `depend_on_referenced_packages` rule is set to `error` in `analysis_options.yaml`.
- **Capture `context`-dependent objects before any `await`** in async widget methods — read blocs, repos, etc. into local variables first, then `await`. Do not call `context.read<>()` after an await gap. The `use_build_context_synchronously` rule is set to `error`.
- **Always wrap `if`/`else`/`for`/`while` bodies in braces `{}`**, even single-line statements. The `curly_braces_in_flow_control_structures` lint is enabled.
- **Only show names you actually use** in `import … show` clauses. Remove any name not referenced in the file. The `unused_shown_name` rule is set to `error`.

## Testing Conventions
- Unit tests: `test/unit/**/*_test.dart`
- Widget tests: `test/widget/**/*_test.dart`
- BDD specs: `test/features/*.feature`
- Use `blocTest` from `bloc_test` for BLoC tests
- Use `mocktail` for mocking repository dependencies

## CI / Branch Protection
Two GitHub Actions workflows enforce quality on every push to `main`:
- **`ci.yml`** — runs `flutter analyze`, `dart format`, and `flutter test --coverage` on every push and PR
- **`spec-guard.yml`** — **fails the push** if any `lib/` file changed but no `test/features/*.feature` file was updated in the same commit

> Both run on direct pushes to `main` (solo-developer friendly — no PR required).
> To also enforce on PRs when working with a team, add `pull_request: branches: [main]` to each workflow's `on:` block.

## Firebase Backup (Free Tier)
- Anonymous auth or email/password via `FirebaseBackupService`
- Firestore structure: `users/{uid}/decks/{deckId}` and `users/{uid}/flashcards/{cardId}`
- Firebase free (Spark) plan is sufficient for personal use
- Firebase setup requires `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
