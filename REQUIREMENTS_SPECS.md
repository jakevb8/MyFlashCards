# MyFlashCards — Requirements Specs

Queued feature specs. Grep for `## [FEAT-XXX]` to jump to a specific spec.
Completed specs are moved to `REQUIREMENTS_ARCHIVE.md`.

---

## [FEAT-015] Deck Tags & Filtering

**Priority:** P2
**Status:** queued

### Goal
Let users tag decks (e.g. "Spanish", "Biology", "Kids") and filter the deck list by tag, making it easy to navigate a large collection.

### User Stories
- As a learner, I want to add tags to a deck so I can group related decks together.
- As a learner, I want to filter the deck list to show only decks with a specific tag.

### Acceptance Criteria
- `Deck` model gains a `List<String> tags` field (`@HiveField(5)`, nullable/empty-safe for old records).
- Tag editor in `DeckFormScreen`: chip input with autocomplete from existing tags.
- Filter chip row above deck list; tapping a chip filters to matching decks; "All" chip clears filter.
- Tags stored locally in Hive; synced to Firestore `tags` array field when signed in.
- Migration: existing decks without tags field treated as empty list.

### Out of Scope
- Nested tags / hierarchy.
- Tag-based study sessions.

---

## [FEAT-016] Typing Study Mode

**Priority:** P2
**Status:** queued

### Goal
Add a typing mode where the user must type the answer from memory rather than self-rating a flipped card, forcing production recall for stronger retention.

### User Stories
- As a language learner, I want to type the translation of a word to test my production recall, not just recognition.
- As a learner, I want a tolerated match (case-insensitive, minor typos allowed) so one typo doesn't count as wrong.

### Acceptance Criteria
- `StudyMode.typing` added to the existing `StudyMode` enum.
- Typing mode available in `StudyModePicker` sheet.
- Study screen shows a text input instead of flip + rating buttons.
- On submit: correct → auto-advances with `RateCard(quality: 5)`; incorrect → shows correct answer with `RateCard(quality: 0)`.
- Tolerated match: case-insensitive, trim whitespace; optionally ignore punctuation.
- SM-2 scheduling still applied identically to other modes.

### Out of Scope
- Partial-credit scoring.
- Fuzzy matching beyond case/whitespace/punctuation.

---

## [FEAT-017] Deck Collections / Bundled Study

**Priority:** P3
**Status:** queued

### Goal
Let users multi-select decks and study them together in one merged session, useful for exam prep spanning multiple topic decks.

### User Stories
- As a student, I want to select three chapter decks and study all their due cards in one session.

### Acceptance Criteria
- Long-press a deck tile enters multi-select mode; checkboxes appear on all tiles.
- "Study Selected" button appears in the app bar when ≥2 decks are selected.
- Cards from all selected decks are merged and passed to `StudyScreen` as a single list (due-cards filter applied per deck before merging).
- Session complete screen shows total cards studied across all decks.
- Session record written per source deck (or as a bundled record — TBD during implementation).
- If no due cards exist across selected decks, show "You're all caught up!" message.

### Out of Scope
- Saving a collection as a named group.
- Persistent multi-deck study playlists.


