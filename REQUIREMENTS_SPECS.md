# MyFlashCards — Requirements Specs

Queued feature specs. Grep for `## [FEAT-XXX]` to jump to a specific spec.
Completed specs are moved to `REQUIREMENTS_ARCHIVE.md`.

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

