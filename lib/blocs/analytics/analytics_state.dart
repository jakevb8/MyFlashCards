import 'package:equatable/equatable.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

/// One bar in the 7-day chart.
class DailyCount extends Equatable {
  final DateTime date;
  final int count;
  const DailyCount({required this.date, required this.count});
  @override
  List<Object?> get props => [date, count];
}

class AnalyticsLoaded extends AnalyticsState {
  /// Consecutive days (ending today or yesterday) where at least one session
  /// was completed. 0 if the user has never studied or missed yesterday.
  final int streak;

  /// Card counts for each of the last 7 calendar days (oldest → newest).
  final List<DailyCount> last7Days;

  /// Fraction of all-time cards reviewed that were rated correctly (0.0–1.0).
  /// Null if no cards have been reviewed yet.
  final double? accuracy;

  /// Total cards reviewed across all sessions.
  final int totalCardsReviewed;

  const AnalyticsLoaded({
    required this.streak,
    required this.last7Days,
    required this.accuracy,
    required this.totalCardsReviewed,
  });

  @override
  List<Object?> get props => [streak, last7Days, accuracy, totalCardsReviewed];
}

class AnalyticsError extends AnalyticsState {
  final String message;
  const AnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}
