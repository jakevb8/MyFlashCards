import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

part 'flashcard.g.dart';

@HiveType(typeId: 1)
class Flashcard extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String deckId;

  @HiveField(2)
  final String front;

  @HiveField(3)
  final String back;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  /// Number of times this card has been starred (0-3).
  /// When this reaches 3, [archived] is set to true and stars reset to 0.
  @HiveField(6)
  final int starCount;

  /// True when the card has been mastered (starred 3 times).
  /// Archived cards are hidden from the active list and excluded from study.
  @HiveField(7)
  final bool archived;

  // SM-2 spaced repetition fields (null = card has never been scheduled).
  // Old Hive records missing these fields will read them back as null,
  // which SpacedRepetitionService treats as a brand-new card with defaults.

  /// SM-2 ease factor. Starts at 2.5; minimum 1.3. Null = never scheduled.
  @HiveField(8)
  final double? easeFactor;

  /// Current interval in days before the next review. Null = never scheduled.
  @HiveField(9)
  final int? intervalDays;

  /// Consecutive correct review count (quality >= 3). Null = never reviewed.
  @HiveField(10)
  final int? repetitions;

  /// When this card is next due for review. Null means the card is new and due immediately.
  @HiveField(11)
  final DateTime? nextReviewAt;

  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    required this.updatedAt,
    this.starCount = 0,
    this.archived = false,
    this.easeFactor,
    this.intervalDays,
    this.repetitions,
    this.nextReviewAt,
  });

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? starCount,
    bool? archived,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReviewAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      starCount: starCount ?? this.starCount,
      archived: archived ?? this.archived,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'deckId': deckId,
    'front': front,
    'back': back,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'starCount': starCount,
    'archived': archived,
    if (easeFactor != null) 'easeFactor': easeFactor,
    if (intervalDays != null) 'intervalDays': intervalDays,
    if (repetitions != null) 'repetitions': repetitions,
    if (nextReviewAt != null) 'nextReviewAt': nextReviewAt!.toIso8601String(),
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'] as String,
    deckId: json['deckId'] as String,
    front: json['front'] as String,
    back: json['back'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    starCount: (json['starCount'] as num?)?.toInt() ?? 0,
    archived: json['archived'] as bool? ?? false,
    easeFactor: (json['easeFactor'] as num?)?.toDouble(),
    intervalDays: (json['intervalDays'] as num?)?.toInt(),
    repetitions: (json['repetitions'] as num?)?.toInt(),
    nextReviewAt: json['nextReviewAt'] != null
        ? DateTime.parse(json['nextReviewAt'] as String)
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    deckId,
    front,
    back,
    createdAt,
    updatedAt,
    starCount,
    archived,
    easeFactor,
    intervalDays,
    repetitions,
    nextReviewAt,
  ];
}
