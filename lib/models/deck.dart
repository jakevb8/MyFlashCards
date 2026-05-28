import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

part 'deck.g.dart';

@HiveType(typeId: 0)
class Deck extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  /// User-defined tags (e.g. "spanish", "biology"). Always lowercase.
  /// Old records missing this field will be read as null by the Hive adapter
  /// and defaulted to an empty list at construction time.
  @HiveField(5)
  final List<String> tags;

  const Deck({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  Deck copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'tags': tags,
  };

  factory Deck.fromJson(Map<String, dynamic> json) => Deck(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    // Handle old JSON without 'tags' field (backups, imports, shared decks).
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
    tags,
  ];
}
