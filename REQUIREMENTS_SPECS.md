# MyFlashCards — Requirements Specs

Queued feature specs. Grep for `## [FEAT-XXX]` to jump to a specific spec.
Completed specs are moved to `REQUIREMENTS_ARCHIVE.md`.

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


