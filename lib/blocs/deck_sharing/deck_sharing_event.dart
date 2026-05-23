import 'package:equatable/equatable.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';

abstract class DeckSharingEvent extends Equatable {
  const DeckSharingEvent();
  @override
  List<Object?> get props => [];
}

/// User tapped the Share action for a deck.
///
/// The bloc publishes the deck to Firestore and emits [DeckSharingSuccess]
/// with the generated deep-link string.
class ShareDeckRequested extends DeckSharingEvent {
  final Deck deck;
  final List<Flashcard> cards;

  const ShareDeckRequested({required this.deck, required this.cards});

  @override
  List<Object?> get props => [deck, cards];
}
