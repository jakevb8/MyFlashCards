# MyFlashCards — Requirements Specs

Queued feature specs. Grep for `## [FEAT-XXX]` to jump to a specific spec.
Completed specs are moved to `REQUIREMENTS_ARCHIVE.md`.

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

