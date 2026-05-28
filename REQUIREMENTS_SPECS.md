# MyFlashCards — Requirements Specs

Queued feature specs. Grep for `## [FEAT-XXX]` to jump to a specific spec.
Completed specs are moved to `REQUIREMENTS_ARCHIVE.md`.

---

## [FEAT-011] Per-Deck Progress Dashboard

**Priority:** P1
**Status:** queued

### Goal
Show at-a-glance progress stats on each deck tile in the deck list screen so users can see which decks need attention and which are nearly mastered — without leaving the home screen.

### User Stories
- As a learner, I want to see how many cards are due today in each deck, so I know where to focus.
- As a learner, I want to see how many cards I've mastered (archived) in a deck, so I feel a sense of progress.

### Acceptance Criteria
- Each deck tile shows: due-today count, total active cards, archived (mastered) count.
- Stats are computed from local Hive data at deck list load time — no network calls.
- Zero-due decks show a subtle "all caught up" indicator.
- No changes to Deck or Flashcard data models required.

### Out of Scope
- Per-deck historical graphs (separate feature).
- Sync of stats to Firestore.

---

## [FEAT-012] Study Goals & Milestones

**Priority:** P1
**Status:** queued

### Goal
Let users set a daily card-study goal and celebrate milestone moments (first deck mastered, 100-card streak, etc.) to create a stronger motivational feedback loop.

### User Stories
- As a learner, I want to set a daily goal (e.g. study 20 cards), so I have a concrete target.
- As a learner, I want to see my progress toward today's goal on the home screen.
- As a learner, I want a celebration moment when I hit a milestone, so studying feels rewarding.

### Acceptance Criteria
- Daily goal configurable in Settings (integer, default 10 cards).
- Home screen shows a progress bar or chip: "12 / 20 today".
- Milestones detected: first session completed, 7-day streak, 30-day streak, 50 cards mastered, 100 cards mastered, first deck fully mastered.
- Celebration shown as confetti overlay on session-complete screen when a milestone is hit.
- Milestone state persisted in `shared_preferences` (don't re-trigger seen milestones).

### Out of Scope
- Social / leaderboard sharing of milestones.
- Custom milestone definitions.

---

## [FEAT-013] Card-Level Edit During Study

**Priority:** P1
**Status:** queued

### Goal
Allow users to edit the current flashcard inline during a study session without losing their place, so typos and errors can be fixed at the moment of discovery.

### User Stories
- As a learner, I want to tap an edit icon while studying a card and fix a typo, then return to the same card in the session.

### Acceptance Criteria
- A floating edit icon appears in the study screen app bar or card area.
- Tapping it pushes `FlashcardFormScreen` pre-populated with the current card.
- On save, the session resumes on the same card with the updated content.
- On cancel, the session resumes unchanged.
- StudyBloc handles a `CardUpdatedInSession` event to refresh displayed card state.

### Out of Scope
- Bulk editing during study.
- Deleting a card during study.

---

## [FEAT-014] AI Card Regeneration

**Priority:** P2
**Status:** queued

### Goal
Let users regenerate a single AI-generated flashcard that is vague, wrong, or poorly worded, using Gemini — turning AI generation from a one-shot output into a collaborative draft.

### User Stories
- As a learner, I want to swipe a card and tap "Regenerate" to get a better AI-written version of that card.
- As a learner, I want the regenerated card to replace the old one in-place.

### Acceptance Criteria
- "Regenerate" swipe action added to `FlashcardListScreen` alongside Edit and Delete.
- Only visible when a Gemini API key is saved; shows key-required snackbar otherwise.
- Gemini prompt: rewrite the given front/back to be clearer and more concise.
- Loading spinner shown on the card tile during generation.
- On success, card is updated in Hive (and Firestore if signed in).
- On failure, error snackbar shown; original card unchanged.

### Out of Scope
- Regenerating all cards in a deck at once.
- Choosing from multiple regenerated options.

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


