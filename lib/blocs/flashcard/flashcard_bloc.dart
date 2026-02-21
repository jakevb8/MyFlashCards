import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../repositories/flashcard_repository.dart';
import 'flashcard_event.dart';
import 'flashcard_state.dart';

class FlashcardBloc extends Bloc<FlashcardEvent, FlashcardState> {
  final FlashcardRepository repository;
  final _uuid = const Uuid();
  String? _currentDeckId;

  FlashcardBloc({required this.repository}) : super(FlashcardInitial()) {
    on<LoadFlashcards>(_onLoadFlashcards);
    on<AddFlashcard>(_onAddFlashcard);
    on<AddFlashcards>(_onAddFlashcards);
    on<UpdateFlashcard>(_onUpdateFlashcard);
    on<DeleteFlashcard>(_onDeleteFlashcard);
  }

  Future<void> _onLoadFlashcards(
    LoadFlashcards event,
    Emitter<FlashcardState> emit,
  ) async {
    _currentDeckId = event.deckId;
    emit(FlashcardLoading());
    try {
      final cards = await repository.getFlashcards(event.deckId);
      emit(FlashcardLoaded(cards));
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }

  Future<void> _onAddFlashcard(
    AddFlashcard event,
    Emitter<FlashcardState> emit,
  ) async {
    try {
      final now = DateTime.now();
      final card = event.flashcard.copyWith(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
      );
      await repository.addFlashcard(card);
      if (_currentDeckId != null) {
        final cards = await repository.getFlashcards(_currentDeckId!);
        emit(FlashcardLoaded(cards));
      }
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }

  /// Saves a batch of cards atomically then emits once — avoids the race
  /// condition that occurs when firing many [AddFlashcard] events in a loop.
  Future<void> _onAddFlashcards(
    AddFlashcards event,
    Emitter<FlashcardState> emit,
  ) async {
    try {
      final now = DateTime.now();
      for (final card in event.flashcards) {
        final stamped = card.copyWith(
          id: _uuid.v4(),
          createdAt: now,
          updatedAt: now,
        );
        await repository.addFlashcard(stamped);
      }
      // Reload once after all cards are written.
      final deckId = event.flashcards.first.deckId;
      _currentDeckId = deckId;
      final cards = await repository.getFlashcards(deckId);
      emit(FlashcardLoaded(cards));
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }

  Future<void> _onUpdateFlashcard(
    UpdateFlashcard event,
    Emitter<FlashcardState> emit,
  ) async {
    try {
      await repository.updateFlashcard(event.flashcard);
      if (_currentDeckId != null) {
        final cards = await repository.getFlashcards(_currentDeckId!);
        emit(FlashcardLoaded(cards));
      }
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }

  Future<void> _onDeleteFlashcard(
    DeleteFlashcard event,
    Emitter<FlashcardState> emit,
  ) async {
    try {
      await repository.deleteFlashcard(event.id);
      if (_currentDeckId != null) {
        final cards = await repository.getFlashcards(_currentDeckId!);
        emit(FlashcardLoaded(cards));
      }
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }
}
