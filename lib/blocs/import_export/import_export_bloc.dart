// ImportExportBloc — manages the import state machine and fire-and-forget exports.
//
// Import lifecycle:
//   ImportExportIdle
//     → ImportExportInProgress  (file picker opens or shared deck fetch starts)
//     → ImportExportIdle         (user cancelled picker)
//     → ImportDuplicateDetected  (name clash; widget shows dialog)
//       → ImportExportInProgress (user chose action)
//       → ImportExportSuccess | ImportExportIdle (cancel)
//     → ImportExportSuccess      (no duplicate)
//
// Export lifecycle:
//   ImportExportInProgress → ImportExportSuccess | ImportExportError
//
// After emitting ImportExportSuccess or ImportExportError the bloc resets to
// ImportExportIdle so subsequent BlocListeners don't re-fire.
//
// This bloc lives at the app-root provider tree so both DeckListScreen and
// FlashcardListScreen can access it. DeckListScreen's BlocListener is
// responsible for calling DeckBloc.add(LoadDecks()) after a successful import
// because this bloc intentionally has no reference to DeckBloc.
//
// ImportSharedDeckRequested flows through the same duplicate-detection machine.
// SM-2 progress is stripped from the received cards so the importer starts fresh.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../repositories/deck_repository.dart';
import '../../repositories/flashcard_repository.dart';
import '../../services/deck_import_export_service.dart';
import '../../services/deck_sharing_service.dart';
import 'import_export_event.dart';
import 'import_export_state.dart';

class ImportExportBloc extends Bloc<ImportExportEvent, ImportExportState> {
  final DeckRepository _deckRepository;
  final FlashcardRepository _flashcardRepository;
  final DeckImportExportService _service;
  final DeckSharingService? _sharingService;

  ImportExportBloc({
    required DeckRepository deckRepository,
    required FlashcardRepository flashcardRepository,
    required DeckImportExportService service,
    DeckSharingService? sharingService,
  }) : _deckRepository = deckRepository,
       _flashcardRepository = flashcardRepository,
       _service = service,
       _sharingService = sharingService,
       super(ImportExportIdle()) {
    on<ImportDeckRequested>(_onImportRequested);
    on<ImportConfirmReplace>(_onConfirmReplace);
    on<ImportConfirmMerge>(_onConfirmMerge);
    on<ImportCancelled>(_onCancelled);
    on<ExportDeckRequested>(_onExportRequested);
    on<ImportSharedDeckRequested>(_onImportSharedRequested);
  }

  /// Opens the file picker, parses the selected file, then either commits the
  /// import directly or emits [ImportDuplicateDetected] when a name clash exists.
  Future<void> _onImportRequested(
    ImportDeckRequested event,
    Emitter<ImportExportState> emit,
  ) async {
    emit(ImportExportInProgress());
    try {
      final bundle = await _service.pickAndParse();
      if (bundle == null) {
        // User dismissed the picker without selecting a file.
        emit(ImportExportIdle());
        return;
      }

      // Check for a name collision.
      final decks = await _deckRepository.getDecks();
      final existing = _findByName(decks, bundle.deck.name);

      if (existing != null) {
        emit(ImportDuplicateDetected(incoming: bundle, existingDeck: existing));
      } else {
        await _commitImport(bundle, emit);
      }
    } catch (e) {
      emit(ImportExportError('Could not import file: $e'));
      emit(ImportExportIdle());
    }
  }

  /// Deletes the existing deck and all its cards, then imports the bundle fresh.
  Future<void> _onConfirmReplace(
    ImportConfirmReplace event,
    Emitter<ImportExportState> emit,
  ) async {
    emit(ImportExportInProgress());
    try {
      // Find the existing deck by name again to get its current ID.
      final decks = await _deckRepository.getDecks();
      final existing = _findByName(decks, event.bundle.deck.name);

      if (existing != null) {
        // Delete existing cards for this deck.
        final oldCards = await _flashcardRepository.getFlashcards(existing.id);
        for (final c in oldCards) {
          await _flashcardRepository.deleteFlashcard(c.id);
        }
        await _deckRepository.deleteDeck(existing.id);
      }

      await _commitImport(event.bundle, emit);
    } catch (e) {
      emit(ImportExportError('Replace failed: $e'));
      emit(ImportExportIdle());
    }
  }

  /// Keeps the existing deck record; inserts only cards whose [Flashcard.id] is
  /// not already present. Rewrites [deckId] on new cards to match [existingDeck.id]
  /// so they are associated with the correct Hive box entry.
  Future<void> _onConfirmMerge(
    ImportConfirmMerge event,
    Emitter<ImportExportState> emit,
  ) async {
    emit(ImportExportInProgress());
    try {
      final existingCards = await _flashcardRepository.getFlashcards(
        event.existingDeck.id,
      );
      final existingIds = existingCards.map((c) => c.id).toSet();

      final newCards = event.bundle.cards
          .where((c) => !existingIds.contains(c.id))
          .map((c) => c.copyWith(deckId: event.existingDeck.id))
          .toList();

      for (final c in newCards) {
        await _flashcardRepository.addFlashcard(c);
      }

      emit(
        ImportExportSuccess(
          'Merged ${newCards.length} new card${newCards.length == 1 ? '' : 's'} '
          'into "${event.existingDeck.name}"',
        ),
      );
      emit(ImportExportIdle());
    } catch (e) {
      emit(ImportExportError('Merge failed: $e'));
      emit(ImportExportIdle());
    }
  }

  void _onCancelled(ImportCancelled event, Emitter<ImportExportState> emit) {
    emit(ImportExportIdle());
  }

  /// Writes the encoded file to the temp directory and invokes the share sheet.
  Future<void> _onExportRequested(
    ExportDeckRequested event,
    Emitter<ImportExportState> emit,
  ) async {
    emit(ImportExportInProgress());
    try {
      await _service.exportAndShare(
        event.deck,
        event.cards,
        format: event.format,
      );
      emit(ImportExportSuccess('Deck exported as .${event.format}'));
      emit(ImportExportIdle());
    } catch (e) {
      emit(ImportExportError('Export failed: $e'));
      emit(ImportExportIdle());
    }
  }

  /// Fetches the shared deck from Firestore and runs the standard import flow.
  ///
  /// SM-2 progress (easeFactor, intervalDays, repetitions, nextReviewAt) is
  /// stripped from each card so the receiver starts with a clean slate.
  /// New UUIDs are assigned to both the deck and all cards to avoid ID
  /// collisions if the same share link is imported more than once.
  Future<void> _onImportSharedRequested(
    ImportSharedDeckRequested event,
    Emitter<ImportExportState> emit,
  ) async {
    if (_sharingService == null) {
      emit(const ImportExportError('Sharing service not available.'));
      emit(ImportExportIdle());
      return;
    }

    emit(ImportExportInProgress());
    try {
      final raw = await _sharingService.fetchSharedDeck(event.shareId);

      // Assign fresh IDs so the receiver's copy is independent of the sender's.
      const uuid = Uuid();
      final newDeckId = uuid.v4();
      final freshDeck = Deck(
        id: newDeckId,
        name: raw.deck.name,
        description: raw.deck.description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Strip SM-2 progress — receiver starts each card as unseen.
      final freshCards = raw.cards.map((c) {
        return Flashcard(
          id: uuid.v4(),
          deckId: newDeckId,
          front: c.front,
          back: c.back,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          starCount: 0,
          archived: false,
          // easeFactor, intervalDays, repetitions, nextReviewAt intentionally omitted
        );
      }).toList();

      final bundle = DeckImportExportBundle(deck: freshDeck, cards: freshCards);

      final decks = await _deckRepository.getDecks();
      final existing = _findByName(decks, bundle.deck.name);

      if (existing != null) {
        emit(ImportDuplicateDetected(incoming: bundle, existingDeck: existing));
      } else {
        await _commitImport(bundle, emit);
      }
    } on DeckSharingException catch (e) {
      emit(ImportExportError(e.message));
      emit(ImportExportIdle());
    } catch (e) {
      emit(ImportExportError('Could not import shared deck: $e'));
      emit(ImportExportIdle());
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Commits an import bundle with no pre-existing conflict.
  ///
  /// Adds the deck first so the foreign-key [Flashcard.deckId] references
  /// a valid deck when cards are written.
  Future<void> _commitImport(
    DeckImportExportBundle bundle,
    Emitter<ImportExportState> emit,
  ) async {
    await _deckRepository.addDeck(bundle.deck);
    for (final c in bundle.cards) {
      await _flashcardRepository.addFlashcard(c);
    }
    final count = bundle.cards.length;
    emit(
      ImportExportSuccess(
        'Imported "${bundle.deck.name}" ($count card${count == 1 ? '' : 's'})',
      ),
    );
    emit(ImportExportIdle());
  }

  /// Returns the first deck whose name matches [name] (case-insensitive), or null.
  Deck? _findByName(List<Deck> decks, String name) {
    final lower = name.toLowerCase();
    try {
      return decks.firstWhere((d) => d.name.toLowerCase() == lower);
    } catch (_) {
      return null;
    }
  }
}
