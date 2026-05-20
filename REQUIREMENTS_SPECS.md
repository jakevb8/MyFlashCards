# MyFlashCards — Requirements Specs

Queued feature specs. Grep for `## [FEAT-XXX]` to jump to a specific spec.
Completed specs are moved to `REQUIREMENTS_ARCHIVE.md`.

---

## [FEAT-001] Google Sign-In

**Goal:** Replace the current GitHub OAuth flow with Google Sign-In so users can authenticate with their Google account using a first-class, low-friction flow.

**Why:** GitHub OAuth requires a browser redirect + deep-link callback — clunky on mobile. Google Sign-In is native, one-tap on Android, and is the standard for Firebase-backed Flutter apps. It also unlocks the user's Google identity for future features (e.g. Google Drive export).

**Scope:**
- Add `google_sign_in` package
- Create `GoogleAuthService` in `lib/services/` wrapping `GoogleSignIn` + `FirebaseAuth.signInWithCredential`
- Add a "Sign in with Google" button on the login/welcome screen
- Wire the existing `AuthBloc` (or create one) to handle `GoogleSignInRequested`, `GoogleSignInSuccess`, `GoogleSignInFailure` events
- On success, navigate to `DeckListScreen`
- On failure, show a typed `AuthException` (never raw `FirebaseAuthException`)
- Keep anonymous / guest mode if it already exists — Google Sign-In is additive
- Update Firestore security rules to confirm `request.auth.uid` ownership still holds (it does — Google Sign-In still produces a Firebase UID)

**Acceptance Criteria:**
- [ ] User can tap "Sign in with Google", complete the Google consent screen, and land on the deck list
- [ ] User's UID-namespaced Firestore data is accessible immediately after sign-in
- [ ] Signing out clears credentials (`GoogleSignIn.signOut()` + `FirebaseAuth.signOut()`)
- [ ] `flutter test` and `flutter analyze` pass with zero issues
- [ ] No hardcoded credentials anywhere

**Packages to add:**
```yaml
google_sign_in: ^6.2.2
```

**Files to create/modify:**
- `lib/services/google_auth_service.dart` (new)
- `lib/blocs/auth/` (new — `auth_bloc.dart`, `auth_event.dart`, `auth_state.dart`)
- `lib/screens/auth/login_screen.dart` (new or modify existing)
- `pubspec.yaml`

---

## [FEAT-002] Gemini API Key Settings

**Goal:** Let users enter their own Google Gemini API key in a Settings screen, with an in-app walkthrough explaining how to get a free key. The key is stored securely and used for all AI card-generation features.

**Why:** Sharing a single hardcoded Gemini key would expose it in the binary and eat quota from one account. User-supplied keys are the right model for a free/open app — each user is responsible for their own quota, and keys stay private.

**Scope:**

### Settings Screen (`lib/screens/settings/settings_screen.dart`)
- New screen accessible from the top-right menu on `DeckListScreen`
- Sections: **AI Settings**, **Account**, **About**
- AI Settings section contains:
  - A masked text field showing the stored key (last 4 chars visible, rest `••••`)
  - "How to get a free Gemini key" link that opens the in-app walkthrough
  - Save / Clear buttons
  - Inline validation (non-empty, starts with `AIza`, length ≥ 39)

### Walkthrough (`lib/screens/settings/gemini_key_walkthrough.dart`)
- A 4-step `PageView` explaining:
  1. **What is Gemini?** — Brief explanation, why the app needs a key
  2. **Go to Google AI Studio** — Button that opens `https://aistudio.google.com/app/apikey` in the browser
  3. **Create an API key** — Screenshot-style illustration + text instructions ("Click 'Create API key', choose a project or create one")
  4. **Paste it here** — Deep-link back to the settings field, or instructions to copy/paste
- "Skip" button on every step; "Done" on the last step

### Secure Storage
- Store key under the key `gemini_api_key` using `flutter_secure_storage`
- `GeminiKeyService` in `lib/services/gemini_key_service.dart` wraps read/write/delete
- `AiDeckService` reads the key from `GeminiKeyService` at call time — never stores it in memory longer than needed

### BLoC (`lib/blocs/settings/`)
- `SettingsBloc` handles `GeminiKeyChanged`, `GeminiKeySaved`, `GeminiKeyCleared`
- State includes `geminiKeyStatus`: `unknown | set | notSet`

**Acceptance Criteria:**
- [ ] User can navigate to Settings and see a masked key field
- [ ] Tapping "How to get a free Gemini key" launches the walkthrough
- [ ] Saving a valid key persists it to Secure Storage (survives app restart)
- [ ] Clearing the key removes it from Secure Storage
- [ ] `AiDeckService` reads the key from Secure Storage, never a hardcoded fallback
- [ ] If no key is set and the user tries to generate cards, they are prompted to add a key first
- [ ] `flutter test` and `flutter analyze` pass

**Packages to add:**
```yaml
flutter_secure_storage: ^9.2.4
url_launcher: ^6.3.1
```

**Files to create/modify:**
- `lib/services/gemini_key_service.dart` (new)
- `lib/blocs/settings/settings_bloc.dart` (new)
- `lib/blocs/settings/settings_event.dart` (new)
- `lib/blocs/settings/settings_state.dart` (new)
- `lib/screens/settings/settings_screen.dart` (new)
- `lib/screens/settings/gemini_key_walkthrough.dart` (new)
- `lib/services/ai_deck_service.dart` (modify — read key from `GeminiKeyService`)
- `pubspec.yaml`

---

## [FEAT-003] Spaced Repetition (SM-2)

**Goal:** Replace the current random-shuffle study mode with the SM-2 spaced repetition algorithm so cards are scheduled based on how well the user knows them.

**Why:** Spaced repetition is significantly more effective for long-term retention than random review. It's the core value-add over a simple flashcard app.

**Scope:**
- Add `ease_factor`, `interval_days`, `repetitions`, and `next_review_at` fields to the `Flashcard` model (Hive migration required)
- `SpacedRepetitionService` in `lib/services/` implements SM-2: given a card + rating (0–5), returns updated scheduling fields
- `StudyBloc` loads only cards due today (`next_review_at <= now`), ordered by due date
- Study screen shows a rating bar (1–5 or Again/Hard/Good/Easy) after flipping a card
- Persist updated scheduling fields to Hive (and Firestore if signed in)

**Acceptance Criteria:**
- [ ] Cards rated poorly are shown again sooner; cards rated well are deferred by days/weeks
- [ ] Hive migration increments the type adapter version without data loss
- [ ] Study session ends when all due cards are reviewed
- [ ] `flutter test` passes including unit tests for `SpacedRepetitionService`

---

## [FEAT-004] Study Analytics & Streaks

**Goal:** Show users their study streak, daily card count, and accuracy over time on a simple analytics screen.

**Why:** Progress visibility is a primary motivator for consistent study habits.

**Scope:**
- `StudySession` model: date, cards reviewed, correct count
- Persist sessions to Hive; sync to Firestore when signed in
- Analytics screen: streak counter, 7-day bar chart (cards reviewed per day), accuracy percentage
- Streak resets if user misses a day

**Acceptance Criteria:**
- [ ] Streak shown on deck list screen as a chip/badge
- [ ] Analytics screen accessible from the top menu
- [ ] Chart renders with no external charting dependency unless `fl_chart` is approved

---

## [FEAT-005] Multiple Study Modes

**Goal:** Offer three study modes — Flashcard Flip (current), Multiple Choice, and Type the Answer — selectable before starting a session.

**Why:** Different study modes engage different recall pathways, improving retention. Multiple choice is lower friction for beginners.

**Scope:**
- Mode picker bottom sheet before `StudyScreen` launches
- Multiple Choice: 4 options, 3 distractors drawn randomly from the same deck
- Type the Answer: text field, case-insensitive exact match (with a "close enough" tolerance toggle)
- All modes feed into the same SM-2 rating pipeline (FEAT-003 prerequisite)

---

## [FEAT-006] Deck Import / Export

**Goal:** Let users export a deck as a CSV or JSON file and import decks from the same formats.

**Why:** Enables users to create cards in spreadsheets, share decks with friends, or back up data independently of Firebase.

**Scope:**
- Export: `DeckExportService` serializes deck + cards to CSV (front, back, tags) or JSON
- Import: parse CSV/JSON via `file_picker`, validate schema, create deck + cards in Hive
- Handle duplicates: prompt user to merge or replace
- `file_picker` is already in `pubspec.yaml`

---

## [FEAT-007] Deck Sharing via Link

**Goal:** Generate a shareable deep link for a deck that another user can open to import a copy of that deck into their app.

**Why:** Viral sharing is a growth mechanic — good for adoption and useful for study groups.

**Scope:**
- Publish the deck (cards + metadata) to a public Firestore collection (`/shared_decks/{shareId}`) with a TTL
- Generate a dynamic link (Firebase Dynamic Links or a custom short URL)
- Receiving user: deep link opens the app, prompts to import, saves to Hive under their UID
- Shared deck is read-only; receiving user gets their own copy

**Dependencies:** FEAT-006 (export model reusable for the shared deck payload)

---

## [FEAT-009] Privacy & Account Management

**Goal:** Meet Play Store privacy requirements and give users meaningful control over their data — a privacy policy screen, account deletion, and removal of anonymous auth from the backup flow.

**Why:** Google Play requires a privacy policy URL if the app collects or transmits user data. Firebase backup qualifies. Account deletion is required by Play Store policy (since May 2024) for apps with account creation. Anonymous auth in the backup flow creates orphaned Firestore data with no real owner.

**Scope:**

### 1. Privacy policy screen (`lib/screens/settings/privacy_policy_screen.dart`)
- Static scrollable screen summarising:
  - What is collected: flashcard content, theme preferences
  - Where it's stored: Google Firebase (Firestore), on-device (Hive)
  - How to delete: via "Delete account" in Settings
  - No third-party analytics or advertising
- Accessible from Settings → About
- Hosted URL (GitHub Pages or similar) for the Play Store listing field — link opens via `url_launcher`

### 2. Account deletion (`lib/services/account_deletion_service.dart`)
- Deletes all `/users/{uid}/` Firestore data (decks, flashcards, meta subcollections) in batches
- Calls `FirebaseAuth.instance.currentUser!.delete()` after Firestore cleanup
- Clears local Hive data and SharedPreferences
- On `requires-recent-login` error, prompts re-authentication before retrying
- "Delete my account" button in Settings → Account section with a confirmation dialog

### 3. Remove anonymous auth from backup flow (depends on FEAT-001)
- Once Google Sign-In is the primary auth method, replace the "Sign in anonymously" backup option with a message: *"Sign in with Google to enable backup"*
- Anonymous accounts can still use the app locally — just not backup

**Acceptance Criteria:**
- [ ] Privacy policy screen is reachable from Settings
- [ ] "Delete my account" deletes all Firestore data then the Firebase Auth account
- [ ] After deletion, app returns to a signed-out state with empty local storage
- [ ] Anonymous auth entry point removed from BackupScreen (post FEAT-001)
- [ ] Privacy policy URL provided for Play Store listing
- [ ] `flutter test` and `flutter analyze` pass

**Packages needed:** `url_launcher` (already required by FEAT-002)

**Dependencies:** FEAT-009 step 3 depends on FEAT-001 (Google Sign-In)
