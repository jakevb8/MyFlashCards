import 'package:equatable/equatable.dart';

abstract class DeckSharingState extends Equatable {
  const DeckSharingState();
  @override
  List<Object?> get props => [];
}

/// Default state — no sharing in progress.
class DeckSharingIdle extends DeckSharingState {}

/// Firestore publish is in progress.
class DeckSharingInProgress extends DeckSharingState {}

/// Deck was published successfully.
///
/// [shareLink] is the full deep-link string to display/share
/// (e.g. "myflashcards://deck/{shareId}").
class DeckSharingSuccess extends DeckSharingState {
  final String shareLink;
  const DeckSharingSuccess(this.shareLink);

  @override
  List<Object?> get props => [shareLink];
}

/// Publishing failed. [message] describes the error for display.
class DeckSharingError extends DeckSharingState {
  final String message;
  const DeckSharingError(this.message);

  @override
  List<Object?> get props => [message];
}
