import 'package:equatable/equatable.dart';
import '../../models/deck.dart';
import '../../services/deck_import_export_service.dart';

abstract class ImportExportState extends Equatable {
  const ImportExportState();
  @override
  List<Object?> get props => [];
}

/// Default state — nothing in progress.
class ImportExportIdle extends ImportExportState {}

/// A pick or export operation is running.
class ImportExportInProgress extends ImportExportState {}

/// File was parsed and a deck with the same name already exists locally.
/// The widget layer reads this state to show the duplicate-resolution dialog
/// and then dispatches [ImportConfirmReplace], [ImportConfirmMerge], or
/// [ImportCancelled].
class ImportDuplicateDetected extends ImportExportState {
  final DeckImportExportBundle incoming;
  final Deck existingDeck;
  const ImportDuplicateDetected({
    required this.incoming,
    required this.existingDeck,
  });
  @override
  List<Object?> get props => [incoming, existingDeck];
}

/// Operation completed successfully.
///
/// [message] is a human-readable summary ("Deck imported (12 cards)" or "Shared!").
/// The widget layer shows this as a SnackBar and reloads the deck list.
class ImportExportSuccess extends ImportExportState {
  final String message;
  const ImportExportSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

/// Operation failed. [message] describes the error for display.
class ImportExportError extends ImportExportState {
  final String message;
  const ImportExportError(this.message);
  @override
  List<Object?> get props => [message];
}
