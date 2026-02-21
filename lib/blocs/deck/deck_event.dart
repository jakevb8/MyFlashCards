import 'package:equatable/equatable.dart';
import '../../models/deck.dart';

abstract class DeckEvent extends Equatable {
  const DeckEvent();
  @override
  List<Object?> get props => [];
}

class LoadDecks extends DeckEvent {}

class AddDeck extends DeckEvent {
  final Deck deck;
  const AddDeck(this.deck);
  @override
  List<Object?> get props => [deck];
}

class UpdateDeck extends DeckEvent {
  final Deck deck;
  const UpdateDeck(this.deck);
  @override
  List<Object?> get props => [deck];
}

class DeleteDeck extends DeckEvent {
  final String id;
  const DeleteDeck(this.id);
  @override
  List<Object?> get props => [id];
}
