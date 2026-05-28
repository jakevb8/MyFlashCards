import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../repositories/deck_repository.dart';
import 'deck_event.dart';
import 'deck_state.dart';

class DeckBloc extends Bloc<DeckEvent, DeckState> {
  final DeckRepository repository;
  final _uuid = const Uuid();

  DeckBloc({required this.repository}) : super(DeckInitial()) {
    on<LoadDecks>(_onLoadDecks);
    on<AddDeck>(_onAddDeck);
    on<UpdateDeck>(_onUpdateDeck);
    on<DeleteDeck>(_onDeleteDeck);
    on<FilterDecksByTag>(_onFilterDecksByTag);
  }

  Future<void> _onLoadDecks(LoadDecks event, Emitter<DeckState> emit) async {
    emit(DeckLoading());
    try {
      final decks = await repository.getDecks();
      emit(DeckLoaded(decks));
    } catch (e) {
      emit(DeckError(e.toString()));
    }
  }

  Future<void> _onAddDeck(AddDeck event, Emitter<DeckState> emit) async {
    try {
      final now = DateTime.now();
      // Preserve the caller-supplied id (used by AI generation to match
      // flashcard deckId). Only generate a new one if id is empty.
      final deck = event.deck.copyWith(
        id: event.deck.id.isNotEmpty ? event.deck.id : _uuid.v4(),
        createdAt: now,
        updatedAt: now,
      );
      await repository.addDeck(deck);
      final decks = await repository.getDecks();
      emit(DeckLoaded(decks));
    } catch (e) {
      emit(DeckError(e.toString()));
    }
  }

  Future<void> _onUpdateDeck(UpdateDeck event, Emitter<DeckState> emit) async {
    try {
      await repository.updateDeck(event.deck);
      final decks = await repository.getDecks();
      emit(DeckLoaded(decks));
    } catch (e) {
      emit(DeckError(e.toString()));
    }
  }

  Future<void> _onDeleteDeck(DeleteDeck event, Emitter<DeckState> emit) async {
    try {
      await repository.deleteDeck(event.id);
      final decks = await repository.getDecks();
      emit(DeckLoaded(decks));
    } catch (e) {
      emit(DeckError(e.toString()));
    }
  }

  /// Updates the active tag filter without touching the repository.
  ///
  /// [event.tag] == null clears the filter ("All" selected).
  /// The filtered view is computed in the UI from the full [DeckLoaded.decks]
  /// list, so this handler is synchronous and never awaits anything.
  void _onFilterDecksByTag(FilterDecksByTag event, Emitter<DeckState> emit) {
    if (state is! DeckLoaded) return;
    final current = state as DeckLoaded;
    emit(current.copyWith(clearTag: event.tag == null, selectedTag: event.tag));
  }
}
