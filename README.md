# MyFlashCards 📚

A **cross-platform Flutter flashcard app** built with spec-driven development (SDD/BDD/TDD).

## Features
- ✅ Create and manage flashcard **decks**
- ✅ Add, edit, and delete **flashcards** (front/back)
- ✅ **Study mode** — flip cards, navigate forward/back
- ✅ **Randomise** cards for varied study sessions
- ✅ **Dark mode** support (Material 3)
- ✅ Swipe to edit/delete (Slidable)
- 🔜 **Cloud backup** via Firebase (free Spark tier)

## Architecture

| Layer | Technology |
|-------|-----------|
| State Management | `flutter_bloc` (BLoC pattern) |
| Local Storage | `hive_ce_flutter` |
| Cloud Backup | Firebase Auth + Cloud Firestore |
| Testing | `flutter_test`, `bloc_test`, `mocktail`, `bdd_widget_test` |
| UI | Material 3, `google_fonts`, `flutter_slidable` |

## Project Structure

```
lib/
├── models/           # Deck, Flashcard (with Hive adapters)
├── repositories/     # Abstract interfaces + Hive implementations
├── blocs/            # BLoC (deck, flashcard, study)
├── screens/          # UI (decks, cards, study)
├── services/         # FirebaseBackupService
└── core/theme/       # AppTheme (light + dark)

test/
├── unit/
│   ├── models/       # Deck, Flashcard model tests
│   └── blocs/        # DeckBloc, StudyBloc tests
├── widget/           # Widget tests
└── features/         # BDD .feature spec files
    ├── deck_management.feature
    ├── flashcard_management.feature
    └── study_session.feature
```

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.8
- iOS Simulator / Android Emulator or physical device

### Run the app
```bash
flutter pub get
flutter run
```

### Run all tests
```bash
flutter test
```

### Run only unit tests
```bash
flutter test test/unit/
```

## Firebase Cloud Backup Setup (Optional — Free)

The app works fully offline without Firebase. To enable cloud backup:

1. Create a project at https://console.firebase.google.com
2. Enable **Authentication** > Email/Password (and/or Anonymous)
3. Enable **Cloud Firestore** (start in test mode, then set rules)
4. Add platform apps:
   - **Android**: download `google-services.json` -> `android/app/`
   - **iOS**: download `GoogleService-Info.plist` -> `ios/Runner/`
5. Run `flutterfire configure` to generate `firebase_options.dart`
6. In `lib/main.dart`, uncomment:
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```

### Firestore Security Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## GitHub OAuth Setup (Mobile)

> **Why does GitHub ask for a URL?**
> GitHub's OAuth app expects a callback URL. For mobile apps you use a
> **custom URL scheme** (e.g. `com.myflashcards.my_flash_cards://`) instead
> of a real web address. Firebase Auth handles the entire OAuth token exchange
> in its own secure browser — your app never sees the client secret.

### How it works on mobile

```
User taps "Sign in with GitHub"
        │
        ▼
Firebase opens SFSafariViewController (iOS)
   or Chrome Custom Tab (Android)
        │
        ▼
GitHub login & consent screen
        │
        ▼
GitHub redirects to:
  https://<your-project>.firebaseapp.com/__/auth/handler
        │
        ▼
Firebase exchanges the code for a token, then redirects to:
  com.myflashcards.my_flash_cards://  (your custom scheme)
        │
        ▼
OS hands the deep link back to your app
        │
        ▼
firebase_auth returns a UserCredential ✅
```

### Step 1 — Create a GitHub OAuth App

1. Go to https://github.com/settings/developers → **OAuth Apps** → **New OAuth App**
2. Fill in the fields:

   | Field | Value |
   |-------|-------|
   | **Application name** | `MyFlashCards` |
   | **Homepage URL** | `https://<your-project-id>.firebaseapp.com` |
   | **Authorization callback URL** | `https://<your-project-id>.firebaseapp.com/__/auth/handler` |

   > Replace `<your-project-id>` with your Firebase project ID
   > (found in Firebase Console → Project Settings → General).
   > This callback URL is Firebase's own server — **not** your mobile app.
   > GitHub redirects here first; Firebase then bounces the user back to your app.

3. Click **Register application**
4. Note your **Client ID**
5. Click **Generate a new client secret** and note the **Client Secret**

### Step 2 — Enable GitHub in Firebase Console

1. Firebase Console → **Authentication** → **Sign-in method** → **GitHub**
2. Toggle **Enable**
3. Paste your GitHub **Client ID** and **Client Secret**
4. Copy the **authorisation callback URL** shown (it should match what you entered in GitHub)
5. Click **Save**

### Step 3 — Register the custom URL scheme on iOS

Firebase needs to redirect back into your app after the OAuth flow.
Add your reversed bundle ID as a URL scheme in `ios/Runner/Info.plist`:

```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <!-- Firebase / Google Sign-In reverse client ID (added by flutterfire configure) -->
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- From GoogleService-Info.plist → REVERSED_CLIENT_ID -->
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

> `flutterfire configure` adds this automatically when you run it.
> Check `ios/Runner/Info.plist` after running it to confirm it is present.

### Step 4 — Register the custom URL scheme on Android

Android handles the redirect via an intent filter. Firebase's
`google-services.json` and the `firebase_auth` plugin handle this
automatically — **no manual changes needed** for Android.

If you need to verify, check that `android/app/src/main/AndroidManifest.xml`
contains an activity with `android:launchMode="singleTop"` (Flutter adds this
by default).

### Step 5 — Install the CLIs (one-time)

```bash
# 1. Install Node.js (if not already installed)
brew install node

# 2. Install the Firebase CLI
npm install -g firebase-tools

# 3. Install the FlutterFire CLI
dart pub global activate flutterfire_cli

# 4. Add the dart pub-cache bin to your PATH (add to ~/.zshrc to make permanent)
export PATH="$PATH":"$HOME/.pub-cache/bin"

# To make it permanent, run:
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc
```

Verify both are working:
```bash
firebase --version     # should print e.g. 15.7.0
flutterfire --version  # should print e.g. 1.3.1
```

### Step 6 — Log in to Firebase

```bash
firebase login
```

This opens a browser for Google authentication. When done:

```bash
firebase projects:list   # confirm your project appears
```

### Step 7 — Sync Firebase config into the app

From inside the project folder:

```bash
cd /path/to/MyFlashCards
flutterfire configure
```

The CLI will:
- Ask which Firebase project to use (select yours)
- Ask which platforms to support (select **android** and **ios**)
- Generate `lib/firebase_options.dart` with all keys baked in
- Patch `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` automatically
- Add the `REVERSED_CLIENT_ID` URL scheme to `ios/Runner/Info.plist` (needed for OAuth redirects)

> Re-run `flutterfire configure` any time you add a new platform or rotate keys.

### Step 8 — Enable Firebase in main.dart

Uncomment the Firebase initialisation in `lib/main.dart`:

```dart
import 'firebase_options.dart'; // ← add this import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DeckAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  await HiveDeckRepository.init();
  await HiveFlashcardRepository.init();

  // ← uncomment this:
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyFlashCardsApp());
}
```

### Step 9 — Use GitHub sign-in in your UI

`FirebaseBackupService.signInWithGitHub()` is already implemented:

```dart
final backupService = FirebaseBackupService();

// Sign in — opens an in-app browser, no passwords stored in your app
final credential = await backupService.signInWithGitHub();
print('Signed in as: ${credential.user?.displayName}');

// Then backup
await backupService.backupDecks(decks);
```

### Troubleshooting

| Symptom | Fix |
|---------|-----|
| "redirect_uri_mismatch" on GitHub | Callback URL in GitHub OAuth app must be exactly `https://<project-id>.firebaseapp.com/__/auth/handler` |
| App does not open after auth | Check `REVERSED_CLIENT_ID` URL scheme is in `Info.plist` (iOS) |
| "operation-not-allowed" from Firebase | GitHub provider not enabled in Firebase Console → Authentication |
| Works on iOS, fails on Android | Ensure `google-services.json` is up to date; re-run `flutterfire configure` |
```

## Spec-Driven Development Workflow

This project follows **Red > Green > Refactor**:

1. Write a `.feature` file or unit test **first**
2. Run tests — confirm they **fail** (Red)
3. Write the **minimum code** to make them pass (Green)
4. **Refactor** for quality

```bash
# Watch tests while developing
flutter test --watch
```
