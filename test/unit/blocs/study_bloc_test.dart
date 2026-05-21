import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/study/study_bloc.dart';
import 'package:my_flash_cards/blocs/study/study_event.dart';
import 'package:my_flash_cards/blocs/study/study_state.dart';
import 'package:my_flash_cards/models/flashcard.dart';
import 'package:my_flash_cards/models/study_mode.dart';
import 'package:my_flash_cards/models/study_session.dart';
import 'package:my_flash_cards/repositories/flashcard_repository.dart';
import 'package:my_flash_cards/repositories/study_session_repository.dart';

class FakeStudySessionRepository implements StudySessionRepository {
  final List<StudySession> sessions = [];

  @override
  Future<List<StudySession>> getSessions() async => List.from(sessions);

  @override
  Future<void> addSession(StudySession session) async => sessions.add(session);

  @override
  Future<void> clearAll() async => sessions.clear();
}

// Minimal in-memory repository used by tests that trigger RateCard.
class FakeFlashcardRepository implements FlashcardRepository {
  final List<Flashcard> _store = [];

  @override
  Future<List<Flashcard>> getFlashcards(String deckId) async =>
      _store.where((c) => c.deckId == deckId).toList();

  @override
  Future<Flashcard> getFlashcard(String id) async =>
      _store.firstWhere((c) => c.id == id);

  @override
  Future<void> addFlashcard(Flashcard flashcard) async => _store.add(flashcard);

  @override
  Future<void> updateFlashcard(Flashcard flashcard) async {
    final idx = _store.indexWhere((c) => c.id == flashcard.id);
    if (idx >= 0) {
      _store[idx] = flashcard;
    } else {
      _store.add(flashcard);
    }
  }

  @override
  Future<void> deleteFlashcard(String id) async =>
      _store.removeWhere((c) => c.id == id);
}

List<Flashcard> makeCards(int count) {
  final now = DateTime(2026, 1, 1);
  return List.generate(
    count,
    (i) => Flashcard(
      id: '$i',
      deckId: 'deck1',
      front: 'Front $i',
      back: 'Back $i',
      createdAt: now,
      updatedAt: now,
      // nextReviewAt == null → new card, always due
    ),
  );
}

StudyBloc makeBloc() => StudyBloc(
  flashcardRepository: FakeFlashcardRepository(),
  sessionRepository: FakeStudySessionRepository(),
);

void main() {
  group('StudyBloc', () {
    blocTest<StudyBloc, StudyState>(
      'emits StudyEmpty when started with no cards',
      build: makeBloc,
      act: (bloc) =>
          bloc.add(const StartStudySession(flashcards: [], randomize: false)),
      expect: () => [isA<StudyEmpty>()],
    );

    blocTest<StudyBloc, StudyState>(
      'emits StudyEmpty when all cards have a future nextReviewAt',
      build: makeBloc,
      act: (bloc) {
        final future = DateTime.now().add(const Duration(days: 3));
        final cards = makeCards(
          2,
        ).map((c) => c.copyWith(nextReviewAt: future)).toList();
        bloc.add(StartStudySession(flashcards: cards, randomize: false));
      },
      expect: () => [isA<StudyEmpty>()],
    );

    blocTest<StudyBloc, StudyState>(
      'filters out not-yet-due cards and only shows due cards',
      build: makeBloc,
      act: (bloc) {
        final future = DateTime.now().add(const Duration(days: 3));
        final overdue = makeCards(1); // nextReviewAt null = due now
        final notDue = makeCards(
          1,
        ).map((c) => c.copyWith(id: 'x', nextReviewAt: future)).toList();
        bloc.add(StartStudySession(flashcards: [...overdue, ...notDue]));
      },
      expect: () => [
        isA<StudyInProgress>().having((s) => s.totalCards, 'only due card', 1),
      ],
    );

    blocTest<StudyBloc, StudyState>(
      'emits StudyInProgress on card 0 when started with cards',
      build: makeBloc,
      act: (bloc) => bloc.add(
        StartStudySession(flashcards: makeCards(3), randomize: false),
      ),
      expect: () => [
        isA<StudyInProgress>()
            .having((s) => s.currentIndex, 'index', 0)
            .having((s) => s.showingFront, 'front', true),
      ],
    );

    blocTest<StudyBloc, StudyState>(
      'FlipCard toggles showingFront',
      build: makeBloc,
      seed: () => StudyInProgress(cards: makeCards(2), currentIndex: 0),
      act: (bloc) => bloc.add(FlipCard()),
      expect: () => [
        isA<StudyInProgress>().having(
          (s) => s.showingFront,
          'back showing',
          false,
        ),
      ],
    );

    blocTest<StudyBloc, StudyState>(
      'NextCard advances to next card and resets to front',
      build: makeBloc,
      seed: () => StudyInProgress(
        cards: makeCards(3),
        currentIndex: 0,
        showingFront: false,
      ),
      act: (bloc) => bloc.add(NextCard()),
      expect: () => [
        isA<StudyInProgress>()
            .having((s) => s.currentIndex, 'index', 1)
            .having((s) => s.showingFront, 'front reset', true),
      ],
    );

    blocTest<StudyBloc, StudyState>(
      'NextCard on last card emits StudyComplete',
      build: makeBloc,
      seed: () => StudyInProgress(cards: makeCards(2), currentIndex: 1),
      act: (bloc) => bloc.add(NextCard()),
      expect: () => [isA<StudyComplete>()],
    );

    blocTest<StudyBloc, StudyState>(
      'PreviousCard goes back one card',
      build: makeBloc,
      seed: () => StudyInProgress(cards: makeCards(3), currentIndex: 2),
      act: (bloc) => bloc.add(PreviousCard()),
      expect: () => [
        isA<StudyInProgress>().having((s) => s.currentIndex, 'index', 1),
      ],
    );

    blocTest<StudyBloc, StudyState>(
      'PreviousCard on first card does nothing',
      build: makeBloc,
      seed: () => StudyInProgress(cards: makeCards(3), currentIndex: 0),
      act: (bloc) => bloc.add(PreviousCard()),
      expect: () => [],
    );

    blocTest<StudyBloc, StudyState>(
      'MarkStarredInSession adds cardId to starredThisSession',
      build: makeBloc,
      seed: () => StudyInProgress(cards: makeCards(2), currentIndex: 0),
      act: (bloc) => bloc.add(const MarkStarredInSession('0')),
      expect: () => [
        isA<StudyInProgress>().having(
          (s) => s.starredThisSession,
          'starred set',
          {'0'},
        ),
      ],
    );

    blocTest<StudyBloc, StudyState>(
      'MarkStarredInSession for second card adds to set without removing first',
      build: makeBloc,
      seed: () => StudyInProgress(
        cards: makeCards(2),
        currentIndex: 0,
        starredThisSession: {'0'},
      ),
      act: (bloc) => bloc.add(const MarkStarredInSession('1')),
      expect: () => [
        isA<StudyInProgress>().having(
          (s) => s.starredThisSession,
          'both cards starred',
          {'0', '1'},
        ),
      ],
    );

    blocTest<StudyBloc, StudyState>(
      'isStarredThisSession returns true only for starred card',
      build: makeBloc,
      seed: () => StudyInProgress(
        cards: makeCards(2),
        currentIndex: 0,
        starredThisSession: {'0'},
      ),
      act: (bloc) {}, // no events needed — verify via seed state
      verify: (bloc) {
        final s = bloc.state as StudyInProgress;
        expect(s.isStarredThisSession('0'), isTrue);
        expect(s.isStarredThisSession('1'), isFalse);
      },
    );

    blocTest<StudyBloc, StudyState>(
      'RateCard on middle card advances index and resets to front',
      build: makeBloc,
      seed: () => StudyInProgress(
        cards: makeCards(3),
        currentIndex: 0,
        showingFront: false,
      ),
      act: (bloc) => bloc.add(const RateCard(cardId: '0', quality: 3)),
      expect: () => [
        isA<StudyInProgress>()
            .having((s) => s.currentIndex, 'index', 1)
            .having((s) => s.showingFront, 'front reset', true),
      ],
    );

    blocTest<StudyBloc, StudyState>(
      'RateCard on last card emits StudyComplete',
      build: makeBloc,
      seed: () => StudyInProgress(
        cards: makeCards(2),
        currentIndex: 1,
        showingFront: false,
      ),
      act: (bloc) => bloc.add(const RateCard(cardId: '1', quality: 5)),
      expect: () => [isA<StudyComplete>()],
    );

    // --- Multiple Choice mode ---

    blocTest<StudyBloc, StudyState>(
      'MC mode: StartStudySession populates choices for first card',
      build: makeBloc,
      act: (bloc) => bloc.add(
        StartStudySession(
          flashcards: makeCards(4),
          mode: StudyMode.multipleChoice,
        ),
      ),
      expect: () => [
        isA<StudyInProgress>().having(
          (s) => s.choices.isNotEmpty,
          'has choices',
          true,
        ),
      ],
    );

    blocTest<StudyBloc, StudyState>(
      'MC mode: choices contain the correct answer',
      build: makeBloc,
      act: (bloc) => bloc.add(
        StartStudySession(
          flashcards: makeCards(4),
          mode: StudyMode.multipleChoice,
        ),
      ),
      verify: (bloc) {
        final s = bloc.state as StudyInProgress;
        expect(s.choices, contains(s.currentCard.back));
      },
    );

    blocTest<StudyBloc, StudyState>(
      'MC mode: choices has at most 4 options',
      build: makeBloc,
      act: (bloc) => bloc.add(
        StartStudySession(
          flashcards: makeCards(4),
          mode: StudyMode.multipleChoice,
        ),
      ),
      verify: (bloc) {
        final s = bloc.state as StudyInProgress;
        expect(s.choices.length, lessThanOrEqualTo(4));
      },
    );

    blocTest<StudyBloc, StudyState>(
      'MC mode: choices with only 1 card still contains the correct answer',
      build: makeBloc,
      act: (bloc) => bloc.add(
        StartStudySession(
          flashcards: makeCards(1),
          mode: StudyMode.multipleChoice,
        ),
      ),
      verify: (bloc) {
        final s = bloc.state as StudyInProgress;
        expect(s.choices, contains(s.currentCard.back));
      },
    );

    blocTest<StudyBloc, StudyState>(
      'MC mode: RateCard advances and generates new choices for next card',
      build: makeBloc,
      act: (bloc) async {
        bloc.add(
          StartStudySession(
            flashcards: makeCards(4),
            mode: StudyMode.multipleChoice,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RateCard(cardId: '0', quality: 5));
      },
      verify: (bloc) {
        if (bloc.state is StudyInProgress) {
          final s = bloc.state as StudyInProgress;
          expect(s.currentIndex, 1);
          expect(s.choices, contains(s.currentCard.back));
        }
      },
    );

    blocTest<StudyBloc, StudyState>(
      'flashcard mode: choices is empty',
      build: makeBloc,
      act: (bloc) => bloc.add(StartStudySession(flashcards: makeCards(3))),
      verify: (bloc) {
        final s = bloc.state as StudyInProgress;
        expect(s.choices, isEmpty);
        expect(s.mode, StudyMode.flashcard);
      },
    );

    blocTest<StudyBloc, StudyState>(
      'typeAnswer mode: choices is empty, tolerantMatching carried through',
      build: makeBloc,
      act: (bloc) => bloc.add(
        StartStudySession(
          flashcards: makeCards(2),
          mode: StudyMode.typeAnswer,
          tolerantMatching: true,
        ),
      ),
      verify: (bloc) {
        final s = bloc.state as StudyInProgress;
        expect(s.choices, isEmpty);
        expect(s.mode, StudyMode.typeAnswer);
        expect(s.tolerantMatching, isTrue);
      },
    );
  });
}
