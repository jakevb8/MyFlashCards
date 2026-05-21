import 'package:equatable/equatable.dart';
import '../../models/flashcard.dart';
import '../../models/study_mode.dart';

abstract class StudyState extends Equatable {
  const StudyState();
  @override
  List<Object?> get props => [];
}

class StudyInitial extends StudyState {}

class StudyInProgress extends StudyState {
  final List<Flashcard> cards;
  final int currentIndex;
  final bool showingFront;

  /// IDs of cards that have been starred during this session (one per card).
  final Set<String> starredThisSession;

  /// The active study mode for this session.
  final StudyMode mode;

  /// Multiple-choice answer options for the current card (correct + distractors),
  /// pre-shuffled. Empty for [StudyMode.flashcard] and [StudyMode.typeAnswer].
  final List<String> choices;

  /// When true, the type-answer checker accepts answers within 2 edit-distance.
  /// Ignored for modes other than [StudyMode.typeAnswer].
  final bool tolerantMatching;

  const StudyInProgress({
    required this.cards,
    required this.currentIndex,
    this.showingFront = true,
    this.starredThisSession = const {},
    this.mode = StudyMode.flashcard,
    this.choices = const [],
    this.tolerantMatching = false,
  });

  Flashcard get currentCard => cards[currentIndex];
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == cards.length - 1;
  int get totalCards => cards.length;

  bool isStarredThisSession(String cardId) =>
      starredThisSession.contains(cardId);

  StudyInProgress copyWith({
    List<Flashcard>? cards,
    int? currentIndex,
    bool? showingFront,
    Set<String>? starredThisSession,
    StudyMode? mode,
    List<String>? choices,
    bool? tolerantMatching,
  }) {
    return StudyInProgress(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      showingFront: showingFront ?? this.showingFront,
      starredThisSession: starredThisSession ?? this.starredThisSession,
      mode: mode ?? this.mode,
      choices: choices ?? this.choices,
      tolerantMatching: tolerantMatching ?? this.tolerantMatching,
    );
  }

  @override
  List<Object?> get props => [
    cards,
    currentIndex,
    showingFront,
    starredThisSession,
    mode,
    choices,
    tolerantMatching,
  ];
}

class StudyComplete extends StudyState {
  final int totalCards;
  const StudyComplete(this.totalCards);
  @override
  List<Object?> get props => [totalCards];
}

class StudyEmpty extends StudyState {}
