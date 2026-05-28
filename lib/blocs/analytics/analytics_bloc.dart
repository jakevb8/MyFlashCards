// AnalyticsBloc — derives streak, 7-day chart data, and accuracy from the
// study session history stored in [StudySessionRepository].
//
// All date arithmetic uses local midnight (DateTime(y, m, d)) so that
// sessions recorded in different timezones are grouped by the user's
// calendar day, not UTC boundaries.
//
// Streak rule: count consecutive calendar days ending today where the user
// completed at least one session. If the user hasn't studied today yet, count
// backwards from yesterday so the streak stays alive until midnight.

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/study_session_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final StudySessionRepository _sessionRepository;

  AnalyticsBloc({required StudySessionRepository sessionRepository})
    : _sessionRepository = sessionRepository,
      super(AnalyticsInitial()) {
    on<LoadAnalytics>(_onLoadAnalytics);
  }

  Future<void> _onLoadAnalytics(
    LoadAnalytics event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final sessions = await _sessionRepository.getSessions();

      // --- Aggregate by date (local midnight) ---
      final Map<DateTime, int> countsByDate = {};
      int totalReviewed = 0;
      int totalCorrect = 0;

      final today = _localMidnight(DateTime.now());
      int todayCount = 0;

      for (final s in sessions) {
        final day = DateTime(s.date.year, s.date.month, s.date.day);
        countsByDate[day] = (countsByDate[day] ?? 0) + s.cardsReviewed;
        totalReviewed += s.cardsReviewed;
        totalCorrect += s.correctCount;
        if (day == today) todayCount += s.cardsReviewed;
      }

      final accuracy = totalReviewed > 0 ? totalCorrect / totalReviewed : null;

      // --- Streak ---
      final streak = _computeStreak(countsByDate, today);

      // --- Last 7 days (oldest to newest) ---
      final last7Days = List.generate(7, (i) {
        final day = today.subtract(Duration(days: 6 - i));
        return DailyCount(date: day, count: countsByDate[day] ?? 0);
      });

      emit(
        AnalyticsLoaded(
          streak: streak,
          last7Days: last7Days,
          accuracy: accuracy,
          totalCardsReviewed: totalReviewed,
          cardsReviewedToday: todayCount,
        ),
      );
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  /// Counts consecutive days with study activity ending at [today].
  /// If [today] has no activity, starts counting from yesterday so the streak
  /// stays alive until the end of the current calendar day.
  int _computeStreak(Map<DateTime, int> countsByDate, DateTime today) {
    final yesterday = today.subtract(const Duration(days: 1));
    final start = countsByDate.containsKey(today) ? today : yesterday;

    if (!countsByDate.containsKey(start)) return 0;

    var streak = 0;
    var day = start;
    while (countsByDate.containsKey(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  DateTime _localMidnight(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
