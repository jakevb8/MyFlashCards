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

  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    required this.updatedAt,
    this.starCount = 0,
    this.archived = false,
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
  );

  @override
  List<Object?> get props =>
      [id, deckId, front, back, createdAt, updatedAt, starCount, archived];
}
