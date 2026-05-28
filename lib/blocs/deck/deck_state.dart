import 'package:equatable/equatable.dart';
import '../../models/deck.dart';

abstract class DeckState extends Equatable {
  const DeckState();
  @override
  List<Object?> get props => [];
}

class DeckInitial extends DeckState {}

class DeckLoading extends DeckState {}

/// Loaded state for the deck list.
///
/// [selectedTag] is the currently active tag filter, or null when all decks
/// are shown. The filter is applied in the UI (not the repository) so that
/// switching tags requires no async operation.
class DeckLoaded extends DeckState {
  final List<Deck> decks;
  final String? selectedTag;

  const DeckLoaded(this.decks, {this.selectedTag});

  /// Returns a new [DeckLoaded] with only the specified fields replaced.
  /// Pass [clearTag] = true to set [selectedTag] back to null.
  DeckLoaded copyWith({
    List<Deck>? decks,
    String? selectedTag,
    bool clearTag = false,
  }) {
    return DeckLoaded(
      decks ?? this.decks,
      selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
    );
  }

  @override
  List<Object?> get props => [decks, selectedTag];
}

class DeckError extends DeckState {
  final String message;
  const DeckError(this.message);
  @override
  List<Object?> get props => [message];
}
