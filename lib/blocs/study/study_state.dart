import 'package:equatable/equatable.dart';
import '../../models/flashcard.dart';

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

  const StudyInProgress({
    required this.cards,
    required this.currentIndex,
    this.showingFront = true,
    this.starredThisSession = const {},
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
  }) {
    return StudyInProgress(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      showingFront: showingFront ?? this.showingFront,
      starredThisSession: starredThisSession ?? this.starredThisSession,
    );
  }

  @override
  List<Object?> get props => [
    cards,
    currentIndex,
    showingFront,
    starredThisSession,
  ];
}

class StudyComplete extends StudyState {
  final int totalCards;
  const StudyComplete(this.totalCards);
  @override
  List<Object?> get props => [totalCards];
}

class StudyEmpty extends StudyState {}
