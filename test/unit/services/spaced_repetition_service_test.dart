import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/models/flashcard.dart';
import 'package:my_flash_cards/services/spaced_repetition_service.dart';

Flashcard makeCard({
  double? easeFactor,
  int? intervalDays,
  int? repetitions,
  DateTime? nextReviewAt,
}) {
  final now = DateTime(2026, 1, 1);
  return Flashcard(
    id: 'test',
    deckId: 'deck1',
    front: 'Q',
    back: 'A',
    createdAt: now,
    updatedAt: now,
    easeFactor: easeFactor,
    intervalDays: intervalDays,
    repetitions: repetitions,
    nextReviewAt: nextReviewAt,
  );
}

void main() {
  final srs = SpacedRepetitionService();

  group('SpacedRepetitionService — new card (nulls treated as defaults)', () {
    test('Easy (5) on new card: interval=1, reps=1, EF increases from 2.5', () {
      final result = srs.schedule(makeCard(), 5);
      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.easeFactor, greaterThan(2.5));
      expect(result.nextReviewAt, isNotNull);
    });

    test('Good (3) on new card: interval=1, reps=1, EF decreases slightly', () {
      final result = srs.schedule(makeCard(), 3);
      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      // q=3 gives EF delta of -0.14
      expect(result.easeFactor, closeTo(2.5 - 0.14, 0.001));
    });

    test(
      'Again (0) on new card: interval=1, reps reset to 0, EF decreases',
      () {
        final result = srs.schedule(makeCard(), 0);
        expect(result.repetitions, 0);
        expect(result.intervalDays, 1);
        expect(result.easeFactor, lessThan(2.5));
      },
    );

    test('Hard (2) on new card: resets reps, interval stays 1', () {
      final result = srs.schedule(makeCard(), 2);
      expect(result.repetitions, 0);
      expect(result.intervalDays, 1);
    });
  });

  group('SpacedRepetitionService — interval ladder', () {
    test('second correct review (reps=1) gives interval=6', () {
      // reps=1 means card has had one successful review already
      final card = makeCard(easeFactor: 2.5, intervalDays: 1, repetitions: 1);
      final result = srs.schedule(card, 3);
      expect(result.intervalDays, 6);
      expect(result.repetitions, 2);
    });

    test('third correct review (reps=2) multiplies interval by EF', () {
      final card = makeCard(easeFactor: 2.5, intervalDays: 6, repetitions: 2);
      final result = srs.schedule(card, 5);
      // newInterval = round(6 * 2.5) = 15
      expect(result.intervalDays, 15);
      expect(result.repetitions, 3);
    });

    test('failure at reps=3 resets to interval=1 and reps=0', () {
      final card = makeCard(easeFactor: 2.5, intervalDays: 15, repetitions: 3);
      final result = srs.schedule(card, 0);
      expect(result.repetitions, 0);
      expect(result.intervalDays, 1);
    });
  });

  group('SpacedRepetitionService — ease factor boundaries', () {
    test('EF never drops below 1.3', () {
      // Start with EF just above minimum and rate 0 repeatedly
      var card = makeCard(easeFactor: 1.4, intervalDays: 1, repetitions: 0);
      for (var i = 0; i < 10; i++) {
        card = srs.schedule(card, 0);
      }
      expect(card.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('EF at exactly 1.3 stays at 1.3 after another failure', () {
      final card = makeCard(easeFactor: 1.3, intervalDays: 1, repetitions: 0);
      final result = srs.schedule(card, 0);
      expect(result.easeFactor, closeTo(1.3, 0.001));
    });

    test('Easy (q=5) raises EF by 0.1', () {
      final card = makeCard(easeFactor: 2.5, intervalDays: 1, repetitions: 0);
      final result = srs.schedule(card, 5);
      expect(result.easeFactor, closeTo(2.6, 0.001));
    });

    test('q=4 leaves EF unchanged', () {
      final card = makeCard(easeFactor: 2.5, intervalDays: 1, repetitions: 0);
      final result = srs.schedule(card, 4);
      expect(result.easeFactor, closeTo(2.5, 0.001));
    });
  });

  group('SpacedRepetitionService — nextReviewAt', () {
    test('nextReviewAt is set to approximately now + intervalDays', () {
      final before = DateTime.now();
      final result = srs.schedule(makeCard(), 5); // interval=1
      final after = DateTime.now();

      final expectedMin = before.add(const Duration(days: 1));
      final expectedMax = after.add(const Duration(days: 1));

      expect(
        result.nextReviewAt!.isAfter(expectedMin) ||
            result.nextReviewAt!.isAtSameMomentAs(expectedMin),
        isTrue,
      );
      expect(
        result.nextReviewAt!.isBefore(expectedMax) ||
            result.nextReviewAt!.isAtSameMomentAs(expectedMax),
        isTrue,
      );
    });
  });

  group('SpacedRepetitionService — immutability', () {
    test('schedule does not mutate the original card', () {
      final card = makeCard(easeFactor: 2.5, intervalDays: 1, repetitions: 0);
      srs.schedule(card, 5);
      // Original must be unchanged
      expect(card.easeFactor, 2.5);
      expect(card.intervalDays, 1);
      expect(card.repetitions, 0);
      expect(card.nextReviewAt, isNull);
    });
  });
}
