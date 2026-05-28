import 'package:equatable/equatable.dart';
import '../../models/flashcard.dart';

abstract class FlashcardState extends Equatable {
  const FlashcardState();
  @override
  List<Object?> get props => [];
}

class FlashcardInitial extends FlashcardState {}

class FlashcardLoading extends FlashcardState {}

/// Loaded state for the active flashcard list.
///
/// [regeneratingIds] tracks which card IDs currently have an in-flight AI
/// regeneration call, so the UI can show a per-card spinner.
///
/// [regenerateError] is a one-shot error string emitted when a regeneration
/// fails. A [BlocListener] in the UI consumes it and shows a SnackBar.
/// The field is cleared back to null on the next successful operation.
class FlashcardLoaded extends FlashcardState {
  final List<Flashcard> flashcards;
  final Set<String> regeneratingIds;
  final String? regenerateError;

  const FlashcardLoaded(
    this.flashcards, {
    this.regeneratingIds = const {},
    this.regenerateError,
  });

  FlashcardLoaded copyWith({
    List<Flashcard>? flashcards,
    Set<String>? regeneratingIds,
    // Sentinel allows explicitly passing null to clear the error field.
    Object? regenerateError = _sentinel,
  }) => FlashcardLoaded(
    flashcards ?? this.flashcards,
    regeneratingIds: regeneratingIds ?? this.regeneratingIds,
    regenerateError: regenerateError == _sentinel
        ? this.regenerateError
        : regenerateError as String?,
  );

  @override
  List<Object?> get props => [flashcards, regeneratingIds, regenerateError];
}

class FlashcardError extends FlashcardState {
  final String message;
  const FlashcardError(this.message);
  @override
  List<Object?> get props => [message];
}

const Object _sentinel = Object();
