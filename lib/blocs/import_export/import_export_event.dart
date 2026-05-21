import 'package:equatable/equatable.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../services/deck_import_export_service.dart';

abstract class ImportExportEvent extends Equatable {
  const ImportExportEvent();
  @override
  List<Object?> get props => [];
}

/// User tapped the import button — opens the file picker.
class ImportDeckRequested extends ImportExportEvent {}

/// User chose "Replace" in the duplicate dialog. Deletes the existing deck
/// and all its cards, then writes the incoming bundle fresh.
class ImportConfirmReplace extends ImportExportEvent {
  final DeckImportExportBundle bundle;
  const ImportConfirmReplace(this.bundle);
  @override
  List<Object?> get props => [bundle];
}

/// User chose "Merge" in the duplicate dialog. Keeps the existing deck record;
/// only inserts cards whose [Flashcard.id] is not already present in the deck.
class ImportConfirmMerge extends ImportExportEvent {
  final DeckImportExportBundle bundle;
  final Deck existingDeck;
  const ImportConfirmMerge({required this.bundle, required this.existingDeck});
  @override
  List<Object?> get props => [bundle, existingDeck];
}

/// User dismissed the duplicate dialog without choosing an action.
class ImportCancelled extends ImportExportEvent {}

/// User requested a deck export. Fire-and-forget: writes to a temp file and
/// triggers the platform share sheet. No navigation side-effects.
class ExportDeckRequested extends ImportExportEvent {
  final Deck deck;
  final List<Flashcard> cards;

  /// Either `'json'` or `'csv'`.
  final String format;

  const ExportDeckRequested({
    required this.deck,
    required this.cards,
    required this.format,
  });

  @override
  List<Object?> get props => [deck, cards, format];
}
