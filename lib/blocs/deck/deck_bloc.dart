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
      final deck = event.deck.copyWith(
        id: _uuid.v4(),
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
}
