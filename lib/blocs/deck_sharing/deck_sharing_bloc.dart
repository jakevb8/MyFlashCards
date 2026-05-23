// DeckSharingBloc — manages the publish (sender) side of deck sharing.
//
// Lifecycle:
//   DeckSharingIdle
//     → DeckSharingInProgress  (Firestore write started)
//     → DeckSharingSuccess(link) (publish succeeded; link shown in dialog)
//     → DeckSharingIdle          (reset so subsequent opens don't re-fire)
//     → DeckSharingError(msg)   (publish failed)
//     → DeckSharingIdle
//
// The receive path (importing a shared deck from a deep link) is handled by
// ImportExportBloc via the ImportSharedDeckRequested event — that reuses the
// existing duplicate-detection and commit state machine.

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/deck_sharing_service.dart';
import 'deck_sharing_event.dart';
import 'deck_sharing_state.dart';

class DeckSharingBloc extends Bloc<DeckSharingEvent, DeckSharingState> {
  final DeckSharingService _service;

  DeckSharingBloc({required DeckSharingService service})
    : _service = service,
      super(DeckSharingIdle()) {
    on<ShareDeckRequested>(_onShareRequested);
  }

  /// Publishes the deck to Firestore and emits the resulting share link.
  ///
  /// Resets to [DeckSharingIdle] after both success and error so the dialog
  /// can re-trigger without the bloc holding stale state.
  Future<void> _onShareRequested(
    ShareDeckRequested event,
    Emitter<DeckSharingState> emit,
  ) async {
    emit(DeckSharingInProgress());
    try {
      final link = await _service.publishSharedDeck(event.deck, event.cards);
      emit(DeckSharingSuccess(link));
      // Reset so a subsequent open of ShareDeckDialog starts from idle.
      emit(DeckSharingIdle());
    } on DeckSharingException catch (e) {
      emit(DeckSharingError(e.message));
      emit(DeckSharingIdle());
    } catch (e) {
      emit(DeckSharingError('Unexpected error: $e'));
      emit(DeckSharingIdle());
    }
  }
}
