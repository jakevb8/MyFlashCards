import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/blocs/analytics/analytics_bloc.dart';
import 'package:my_flash_cards/blocs/analytics/analytics_event.dart';
import 'package:my_flash_cards/blocs/analytics/analytics_state.dart';
import 'package:my_flash_cards/models/study_session.dart';
import 'package:my_flash_cards/repositories/study_session_repository.dart';

class FakeStudySessionRepository implements StudySessionRepository {
  final List<StudySession> _store;
  FakeStudySessionRepository([List<StudySession>? sessions])
    : _store = sessions ?? [];

  @override
  Future<List<StudySession>> getSessions() async => List.from(_store);

  @override
  Future<void> addSession(StudySession session) async => _store.add(session);

  @override
  Future<void> clearAll() async => _store.clear();
}

StudySession makeSession({
  required DateTime date,
  int cardsReviewed = 10,
  int correctCount = 8,
}) => StudySession(
  id: '${date.toIso8601String()}-$cardsReviewed',
  date: date,
  cardsReviewed: cardsReviewed,
  correctCount: correctCount,
);

void main() {
  // Use a fixed "today" for deterministic tests.
  // AnalyticsBloc uses DateTime.now() internally so we verify behaviour
  // by seeding sessions relative to the current date.
  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final yesterday = today.subtract(const Duration(days: 1));
  final twoDaysAgo = today.subtract(const Duration(days: 2));

  group('AnalyticsBloc — empty state', () {
    blocTest<AnalyticsBloc, AnalyticsState>(
      'emits AnalyticsLoaded with zeros when no sessions exist',
      build: () =>
          AnalyticsBloc(sessionRepository: FakeStudySessionRepository()),
      act: (b) => b.add(const LoadAnalytics()),
      expect: () => [
        isA<AnalyticsLoading>(),
        isA<AnalyticsLoaded>()
            .having((s) => s.streak, 'streak', 0)
            .having((s) => s.totalCardsReviewed, 'total', 0)
            .having((s) => s.accuracy, 'accuracy null', null)
            .having((s) => s.last7Days.length, '7 days length', 7),
      ],
    );
  });

  group('AnalyticsBloc — streak', () {
    blocTest<AnalyticsBloc, AnalyticsState>(
      'streak is 1 when only today has a session',
      build: () => AnalyticsBloc(
        sessionRepository: FakeStudySessionRepository([
          makeSession(date: today),
        ]),
      ),
      act: (b) => b.add(const LoadAnalytics()),
      expect: () => [
        isA<AnalyticsLoading>(),
        isA<AnalyticsLoaded>().having((s) => s.streak, 'streak', 1),
      ],
    );

    blocTest<AnalyticsBloc, AnalyticsState>(
      'streak is 1 when only yesterday has a session (today not studied yet)',
      build: () => AnalyticsBloc(
        sessionRepository: FakeStudySessionRepository([
          makeSession(date: yesterday),
        ]),
      ),
      act: (b) => b.add(const LoadAnalytics()),
      expect: () => [
        isA<AnalyticsLoading>(),
        isA<AnalyticsLoaded>().having((s) => s.streak, 'streak', 1),
      ],
    );

    blocTest<AnalyticsBloc, AnalyticsState>(
      'streak is 2 when today and yesterday both have sessions',
      build: () => AnalyticsBloc(
        sessionRepository: FakeStudySessionRepository([
          makeSession(date: today),
          makeSession(date: yesterday),
        ]),
      ),
      act: (b) => b.add(const LoadAnalytics()),
      expect: () => [
        isA<AnalyticsLoading>(),
        isA<AnalyticsLoaded>().having((s) => s.streak, 'streak', 2),
      ],
    );

    blocTest<AnalyticsBloc, AnalyticsState>(
      'streak is 3 when today, yesterday, and 2 days ago all have sessions',
      build: () => AnalyticsBloc(
        sessionRepository: FakeStudySessionRepository([
          makeSession(date: today),
          makeSession(date: yesterday),
          makeSession(date: twoDaysAgo),
        ]),
      ),
      act: (b) => b.add(const LoadAnalytics()),
      expect: () => [
        isA<AnalyticsLoading>(),
        isA<AnalyticsLoaded>().having((s) => s.streak, 'streak', 3),
      ],
    );

    blocTest<AnalyticsBloc, AnalyticsState>(
      'streak resets to 0 when the most recent session was 2+ days ago',
      build: () => AnalyticsBloc(
        sessionRepository: FakeStudySessionRepository([
          makeSession(date: twoDaysAgo),
        ]),
      ),
      act: (b) => b.add(const LoadAnalytics()),
      expect: () => [
        isA<AnalyticsLoading>(),
        isA<AnalyticsLoaded>().having((s) => s.streak, 'streak', 0),
      ],
    );
  });

  group('AnalyticsBloc — accuracy', () {
    blocTest<AnalyticsBloc, AnalyticsState>(
      'accuracy is 0.8 when 8 of 10 cards were correct',
      build: () => AnalyticsBloc(
        sessionRepository: FakeStudySessionRepository([
          makeSession(date: today, cardsReviewed: 10, correctCount: 8),
        ]),
      ),
      act: (b) => b.add(const LoadAnalytics()),
      expect: () => [
        isA<AnalyticsLoading>(),
        isA<AnalyticsLoaded>().having(
          (s) => s.accuracy,
          'accuracy',
          closeTo(0.8, 0.001),
        ),
      ],
    );

    blocTest<AnalyticsBloc, AnalyticsState>(
      'accuracy aggregates across multiple sessions',
      build: () => AnalyticsBloc(
        sessionRepository: FakeStudySessionRepository([
          makeSession(date: today, cardsReviewed: 10, correctCount: 5),
          makeSession(date: yesterday, cardsReviewed: 10, correctCount: 10),
        ]),
      ),
      act: (b) => b.add(const LoadAnalytics()),
      expect: () => [
        isA<AnalyticsLoading>(),
        isA<AnalyticsLoaded>().having(
          (s) => s.accuracy,
          'accuracy 15/20',
          closeTo(0.75, 0.001),
        ),
      ],
    );
  });

  group('AnalyticsBloc — 7-day chart', () {
    blocTest<AnalyticsBloc, AnalyticsState>(
      'last7Days always has 7 entries',
      build: () => AnalyticsBloc(
        sessionRepository: FakeStudySessionRepository([
          makeSession(date: today, cardsReviewed: 5),
        ]),
      ),
      act: (b) => b.add(const LoadAnalytics()),
      verify: (b) {
        final loaded = b.state as AnalyticsLoaded;
        expect(loaded.last7Days.length, 7);
      },
    );

    blocTest<AnalyticsBloc, AnalyticsState>(
      'today\'s card count appears in the last entry of last7Days',
      build: () => AnalyticsBloc(
        sessionRepository: FakeStudySessionRepository([
          makeSession(date: today, cardsReviewed: 7),
        ]),
      ),
      act: (b) => b.add(const LoadAnalytics()),
      verify: (b) {
        final loaded = b.state as AnalyticsLoaded;
        expect(loaded.last7Days.last.count, 7);
        expect(loaded.last7Days.last.date, today);
      },
    );

    blocTest<AnalyticsBloc, AnalyticsState>(
      'multiple sessions on the same day are summed',
      build: () => AnalyticsBloc(
        sessionRepository: FakeStudySessionRepository([
          makeSession(date: today, cardsReviewed: 5),
          makeSession(date: today, cardsReviewed: 3),
        ]),
      ),
      act: (b) => b.add(const LoadAnalytics()),
      verify: (b) {
        final loaded = b.state as AnalyticsLoaded;
        expect(loaded.last7Days.last.count, 8);
      },
    );
  });
}
