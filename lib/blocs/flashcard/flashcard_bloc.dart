import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../models/flashcard.dart';
import '../../repositories/flashcard_repository.dart';
import '../../services/ai_deck_service.dart';
import '../../services/gemini_key_service.dart';
import 'flashcard_event.dart';
import 'flashcard_state.dart';

class FlashcardBloc extends Bloc<FlashcardEvent, FlashcardState> {
  final FlashcardRepository repository;
  final GeminiKeyService _keyService;
  final _uuid = const Uuid();
  String? _currentDeckId;

  FlashcardBloc({required this.repository, GeminiKeyService? keyService})
    : _keyService = keyService ?? GeminiKeyService(),
      super(FlashcardInitial()) {
    on<LoadFlashcards>(_onLoadFlashcards);
    on<AddFlashcard>(_onAddFlashcard);
    on<AddFlashcards>(_onAddFlashcards);
    on<UpdateFlashcard>(_onUpdateFlashcard);
    on<DeleteFlashcard>(_onDeleteFlashcard);
    on<StarCard>(_onStarCard);
    on<UnarchiveCard>(_onUnarchiveCard);
    on<RegenerateFlashcard>(_onRegenerateFlashcard);
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
        id: event.flashcard.id.isNotEmpty ? event.flashcard.id : _uuid.v4(),
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
          id: card.id.isNotEmpty ? card.id : _uuid.v4(),
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

  /// Increment star count. At 3 stars → archive the card and reset stars.
  Future<void> _onStarCard(StarCard event, Emitter<FlashcardState> emit) async {
    try {
      final card = await repository.getFlashcard(event.id);
      final newStars = card.starCount + 1;
      final updated = newStars >= 3
          ? card.copyWith(
              starCount: 0,
              archived: true,
              updatedAt: DateTime.now(),
            )
          : card.copyWith(starCount: newStars, updatedAt: DateTime.now());
      await repository.updateFlashcard(updated);
      if (_currentDeckId != null) {
        final cards = await repository.getFlashcards(_currentDeckId!);
        emit(FlashcardLoaded(cards));
      }
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }

  /// Unarchive a card and reset its star count to 0.
  Future<void> _onUnarchiveCard(
    UnarchiveCard event,
    Emitter<FlashcardState> emit,
  ) async {
    try {
      final card = await repository.getFlashcard(event.id);
      final updated = card.copyWith(
        starCount: 0,
        archived: false,
        updatedAt: DateTime.now(),
      );
      await repository.updateFlashcard(updated);
      if (_currentDeckId != null) {
        final cards = await repository.getFlashcards(_currentDeckId!);
        emit(FlashcardLoaded(cards));
      }
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }

  /// Rewrites a card's front and back using Gemini.
  ///
  /// Shows a per-card spinner via [FlashcardLoaded.regeneratingIds] while the
  /// AI call is in-flight. On success the card is updated in storage and the
  /// list is reloaded. On failure [FlashcardLoaded.regenerateError] carries the
  /// message for the UI's BlocListener to surface as a SnackBar.
  Future<void> _onRegenerateFlashcard(
    RegenerateFlashcard event,
    Emitter<FlashcardState> emit,
  ) async {
    final current = state;
    if (current is! FlashcardLoaded) return;

    // Show per-card spinner.
    emit(
      current.copyWith(
        regeneratingIds: {...current.regeneratingIds, event.id},
        regenerateError: null,
      ),
    );

    try {
      final apiKey = await _keyService.readKey();
      if (apiKey == null || apiKey.isEmpty) {
        final remaining = Set<String>.from(
          (state as FlashcardLoaded).regeneratingIds,
        )..remove(event.id);
        emit(
          (state as FlashcardLoaded).copyWith(
            regeneratingIds: remaining,
            regenerateError: 'No Gemini API key saved. Add one in Settings.',
          ),
        );
        return;
      }

      final card = current.flashcards.firstWhere(
        (c) => c.id == event.id,
        orElse: () => throw StateError('Card not found in state'),
      );

      final suggestion = await GeminiDirectService(
        apiKey,
      ).regenerateCard(card.front, card.back);

      final updated = card.copyWith(
        front: suggestion.front,
        back: suggestion.back,
        updatedAt: DateTime.now(),
      );
      await repository.updateFlashcard(updated);

      if (_currentDeckId != null) {
        final cards = await repository.getFlashcards(_currentDeckId!);
        // Read latest state in case another event fired concurrently.
        final latestIds = state is FlashcardLoaded
            ? Set<String>.from((state as FlashcardLoaded).regeneratingIds)
            : <String>{};
        latestIds.remove(event.id);
        emit(FlashcardLoaded(cards, regeneratingIds: latestIds));
      }
    } catch (e) {
      // Restore spinner-free state and surface the error.
      final latestState = state;
      final remaining = latestState is FlashcardLoaded
          ? (Set<String>.from(latestState.regeneratingIds)..remove(event.id))
          : <String>{};
      List<Flashcard> cards;
      try {
        cards = _currentDeckId != null
            ? await repository.getFlashcards(_currentDeckId!)
            : (latestState is FlashcardLoaded ? latestState.flashcards : []);
      } catch (_) {
        cards = latestState is FlashcardLoaded ? latestState.flashcards : [];
      }
      emit(
        FlashcardLoaded(
          cards,
          regeneratingIds: remaining,
          regenerateError: 'Rewrite failed: ${e.toString()}',
        ),
      );
    }
  }
}
