import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

part 'study_session.g.dart';

/// Records one study session: how many cards the user reviewed and how many
/// they answered correctly (SM-2 quality >= 3).
///
/// [date] is normalised to midnight (no time component) so sessions from the
/// same calendar day can be grouped for streak and chart calculations.
@HiveType(typeId: 2)
class StudySession extends Equatable {
  @HiveField(0)
  final String id;

  /// Calendar day of the session — always stored as midnight UTC to allow
  /// consistent day-boundary comparisons regardless of timezone.
  @HiveField(1)
  final DateTime date;

  /// Total cards shown during the session.
  @HiveField(2)
  final int cardsReviewed;

  /// Cards rated with quality >= 3 (Good or Easy in SM-2 terms).
  @HiveField(3)
  final int correctCount;

  const StudySession({
    required this.id,
    required this.date,
    required this.cardsReviewed,
    required this.correctCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'cardsReviewed': cardsReviewed,
    'correctCount': correctCount,
  };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    cardsReviewed: (json['cardsReviewed'] as num).toInt(),
    correctCount: (json['correctCount'] as num).toInt(),
  );

  @override
  List<Object?> get props => [id, date, cardsReviewed, correctCount];
}
