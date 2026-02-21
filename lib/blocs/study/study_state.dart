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

  const StudyInProgress({
    required this.cards,
    required this.currentIndex,
    this.showingFront = true,
  });

  Flashcard get currentCard => cards[currentIndex];
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == cards.length - 1;
  int get totalCards => cards.length;

  StudyInProgress copyWith({
    List<Flashcard>? cards,
    int? currentIndex,
    bool? showingFront,
  }) {
    return StudyInProgress(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      showingFront: showingFront ?? this.showingFront,
    );
  }

  @override
  List<Object?> get props => [cards, currentIndex, showingFront];
}

class StudyComplete extends StudyState {
  final int totalCards;
  const StudyComplete(this.totalCards);
  @override
  List<Object?> get props => [totalCards];
}

class StudyEmpty extends StudyState {}
