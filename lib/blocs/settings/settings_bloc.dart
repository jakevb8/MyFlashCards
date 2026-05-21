// settings_bloc.dart
//
// BLoC that manages the Gemini API key lifecycle within the Settings screen.
//
// STATE MACHINE OVERVIEW:
//
//   Initial: GeminiKeyStatus.unknown, draftKey='', isSaving=false
//
//   GeminiKeyLoaded
//     → reads key from GeminiKeyService
//     → if key found: emits status=set
//     → if no key:   emits status=notSet
//
//   GeminiKeyChanged(key)
//     → updates draftKey, clears errorMessage
//     → does NOT touch secure storage (draft-only)
//
//   GeminiKeySaved
//     → validates draftKey: must start with 'AIza' AND length >= 39
//     → if invalid:  emits errorMessage (does not save)
//     → if valid:    isSaving=true → saves via GeminiKeyService → status=set, isSaving=false
//     → on storage error: emits errorMessage
//
//   GeminiKeyCleared
//     → isSaving=true → deletes via GeminiKeyService
//     → emits status=notSet, draftKey='', isSaving=false
//     → on storage error: emits errorMessage
//
// WHY THE BLOC OWNS VALIDATION:
//   Validation logic (AIza prefix, length) is a business rule, not a UI rule.
//   Keeping it here means tests can exercise it without spinning up widgets.
//
// WHY WE DON'T STORE THE KEY IN STATE:
//   The actual key value should not live in the BLoC state — state can be
//   logged, replayed in tests, or accidentally printed. We only store the
//   draft (transient) and a boolean status for what's persisted.

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/gemini_key_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// Minimum length for a Google AI Studio API key (real keys are 39 chars).
const _kMinKeyLength = 39;

/// All Google AI Studio API keys start with this prefix.
const _kKeyPrefix = 'AIza';

/// BLoC that manages reading, validating, and persisting the Gemini API key.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GeminiKeyService _keyService;

  SettingsBloc({GeminiKeyService? keyService})
    : _keyService = keyService ?? GeminiKeyService(),
      super(const SettingsState()) {
    on<GeminiKeyLoaded>(_onLoaded);
    on<GeminiKeyChanged>(_onChanged);
    on<GeminiKeySaved>(_onSaved);
    on<GeminiKeyCleared>(_onCleared);
  }

  /// Reads the stored key from secure storage on bloc initialisation.
  ///
  /// Emits [GeminiKeyStatus.set] when a key is found, [GeminiKeyStatus.notSet]
  /// when none has been stored yet. A storage error is surfaced via
  /// [errorMessage] so the UI can inform the user.
  Future<void> _onLoaded(
    GeminiKeyLoaded event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final hasKey = await _keyService.hasKey();
      emit(
        state.copyWith(
          geminiKeyStatus: hasKey
              ? GeminiKeyStatus.set
              : GeminiKeyStatus.notSet,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          geminiKeyStatus: GeminiKeyStatus.notSet,
          errorMessage: 'Could not read stored key: $e',
        ),
      );
    }
  }

  /// Updates the draft text and clears any previous validation error.
  ///
  /// Does not touch secure storage — changes are draft-only until
  /// [GeminiKeySaved] is dispatched.
  void _onChanged(GeminiKeyChanged event, Emitter<SettingsState> emit) {
    emit(state.copyWith(draftKey: event.key, errorMessage: null));
  }

  /// Validates and persists the current draft key.
  ///
  /// Validation rules:
  ///   - Must start with '$_kKeyPrefix'
  ///   - Must be at least $_kMinKeyLength characters long
  ///
  /// On validation failure: emits [errorMessage] without saving.
  /// On storage error: emits [errorMessage] with the exception message.
  Future<void> _onSaved(
    GeminiKeySaved event,
    Emitter<SettingsState> emit,
  ) async {
    final key = state.draftKey.trim();

    // Validate format — both conditions are required for a real Google AI key.
    if (!key.startsWith(_kKeyPrefix) || key.length < _kMinKeyLength) {
      emit(
        state.copyWith(
          errorMessage:
              'Key must start with "$_kKeyPrefix" and be at least $_kMinKeyLength characters.',
        ),
      );
      return;
    }

    emit(state.copyWith(isSaving: true, errorMessage: null));
    try {
      await _keyService.saveKey(key);
      emit(
        state.copyWith(geminiKeyStatus: GeminiKeyStatus.set, isSaving: false),
      );
    } catch (e) {
      emit(
        state.copyWith(isSaving: false, errorMessage: 'Failed to save key: $e'),
      );
    }
  }

  /// Deletes the stored key from secure storage and resets draft state.
  ///
  /// On storage error: emits [errorMessage] but leaves status unchanged so
  /// the user is not silently left with a key they believe is gone.
  Future<void> _onCleared(
    GeminiKeyCleared event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true));
    try {
      await _keyService.clearKey();
      emit(
        state.copyWith(
          geminiKeyStatus: GeminiKeyStatus.notSet,
          draftKey: '',
          isSaving: false,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to clear key: $e',
        ),
      );
    }
  }
}
