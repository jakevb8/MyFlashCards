import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/study/study_bloc.dart';
import 'package:my_flash_cards/blocs/study/study_event.dart';
import 'package:my_flash_cards/blocs/study/study_state.dart';
import 'package:my_flash_cards/models/flashcard.dart';

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
    ),
  );
}

void main() {
  group('StudyBloc', () {
    blocTest<StudyBloc, StudyState>(
      'emits StudyEmpty when started with no cards',
      build: () => StudyBloc(),
      act: (bloc) =>
          bloc.add(const StartStudySession(flashcards: [], randomize: false)),
      expect: () => [isA<StudyEmpty>()],
    );

    blocTest<StudyBloc, StudyState>(
      'emits StudyInProgress on card 0 when started with cards',
      build: () => StudyBloc(),
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
      build: () => StudyBloc(),
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
      build: () => StudyBloc(),
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
      build: () => StudyBloc(),
      seed: () => StudyInProgress(cards: makeCards(2), currentIndex: 1),
      act: (bloc) => bloc.add(NextCard()),
      expect: () => [isA<StudyComplete>()],
    );

    blocTest<StudyBloc, StudyState>(
      'PreviousCard goes back one card',
      build: () => StudyBloc(),
      seed: () => StudyInProgress(cards: makeCards(3), currentIndex: 2),
      act: (bloc) => bloc.add(PreviousCard()),
      expect: () => [
        isA<StudyInProgress>().having((s) => s.currentIndex, 'index', 1),
      ],
    );

    blocTest<StudyBloc, StudyState>(
      'PreviousCard on first card does nothing',
      build: () => StudyBloc(),
      seed: () => StudyInProgress(cards: makeCards(3), currentIndex: 0),
      act: (bloc) => bloc.add(PreviousCard()),
      expect: () => [],
    );

    blocTest<StudyBloc, StudyState>(
      'MarkStarredInSession adds cardId to starredThisSession',
      build: () => StudyBloc(),
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
      build: () => StudyBloc(),
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
      build: () => StudyBloc(),
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
  });
}
