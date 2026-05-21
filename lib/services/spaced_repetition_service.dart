// SpacedRepetitionService — implements the SM-2 algorithm for flashcard scheduling.
//
// Given a card and a quality rating (0–5), returns a copy of the card with
// updated SM-2 fields so it surfaces at the right time in future sessions.
//
// Quality scale used in the app:
//   0 = Again  (complete blackout — show again tomorrow)
//   2 = Hard   (wrong but answer felt close)
//   3 = Good   (correct with some effort)
//   5 = Easy   (perfect, effortless recall)
//
// Invariant: [schedule] never mutates the input card; always returns a new copy.

import '../models/flashcard.dart';

class SpacedRepetitionService {
  /// Returns a new [Flashcard] with SM-2 scheduling applied.
  ///
  /// [quality] must be in [0, 5]. Values < 3 are treated as failures:
  /// they reset the repetition streak and reschedule for tomorrow, but still
  /// adjust the ease factor downward so the card gets more exposure over time.
  Flashcard schedule(Flashcard card, int quality) {
    assert(quality >= 0 && quality <= 5, 'quality must be 0–5');

    final ef = card.easeFactor ?? 2.5;
    final interval = card.intervalDays ?? 1;
    final reps = card.repetitions ?? 0;

    // EF' = EF + (0.1 − (5−q) × (0.08 + (5−q) × 0.02))
    // At q=4 the delta is exactly 0; q>4 raises EF, q<4 lowers it.
    final newEf = (ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
        .clamp(1.3, double.infinity);

    final int newReps;
    final int newInterval;

    if (quality < 3) {
      // Failure — reset streak; keep EF change so future scheduling reflects difficulty.
      newReps = 0;
      newInterval = 1;
    } else {
      // Success — advance through the standard SM-2 interval ladder.
      newReps = reps + 1;
      if (reps == 0) {
        newInterval = 1;
      } else if (reps == 1) {
        newInterval = 6;
      } else {
        // Use the *pre-rating* EF for the interval growth, matching original SM-2.
        newInterval = (interval * ef).round();
      }
    }

    final nextReview = DateTime.now().add(Duration(days: newInterval));

    return card.copyWith(
      easeFactor: newEf,
      intervalDays: newInterval,
      repetitions: newReps,
      nextReviewAt: nextReview,
    );
  }
}
