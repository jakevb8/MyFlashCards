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

## Spec-Driven Development Rules
1. **Write the `.feature` file or unit test FIRST**
2. Run it — confirm it fails (Red)
3. Implement the minimum code to make it pass (Green)
4. Refactor

## Code Conventions
- All models must implement `Equatable` and have `toJson`/`fromJson`
- All BLoC events/states must extend `Equatable`
- Repository interfaces live in `lib/repositories/` as abstract classes
- Hive adapters are hand-written in `.g.dart` files (typeId 0 = Deck, 1 = Flashcard)
- Always use `context.read<BlocType>()` for one-off calls and `BlocBuilder` for UI
- Use Material 3 components and `AppTheme.light` / `AppTheme.dark`

## Testing Conventions
- Unit tests: `test/unit/**/*_test.dart`
- Widget tests: `test/widget/**/*_test.dart`
- BDD specs: `test/features/*.feature`
- Use `blocTest` from `bloc_test` for BLoC tests
- Use `mocktail` for mocking repository dependencies

## Firebase Backup (Free Tier)
- Anonymous auth or email/password via `FirebaseBackupService`
- Firestore structure: `users/{uid}/decks/{deckId}` and `users/{uid}/flashcards/{cardId}`
- Firebase free (Spark) plan is sufficient for personal use
- Firebase setup requires `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
