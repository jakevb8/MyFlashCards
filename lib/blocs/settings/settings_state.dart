// settings_state.dart
//
// Immutable state model for the SettingsBloc.
//
// WHY EQUATABLE:
//   BlocBuilder re-renders only when the state object changes. Equatable's
//   value-equality means we don't force a rebuild when nothing meaningful has
//   changed, keeping UI smooth.
//
// KEY DESIGN DECISIONS:
//   - [draftKey] holds what the user has typed in the text field but has not
//     yet tapped Save on. This lets us show live validation without touching
//     secure storage on every keystroke.
//   - [geminiKeyStatus] is separate from draftKey. The bloc reads the stored
//     key on init and sets this to `set` or `notSet` without exposing the
//     actual key value to the UI (privacy by design).
//   - [errorMessage] is null when clean and non-null when the user tried to
//     save an invalid key. It is cleared the moment the user starts typing.

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tracks whether a Gemini API key has been stored in secure storage.
///
/// [unknown] — initial state before the bloc has read from storage.
/// [set]     — a key is persisted and ready to use.
/// [notSet]  — no key is stored; the user needs to supply one.
enum GeminiKeyStatus { unknown, set, notSet }

/// Immutable snapshot of the settings screen's relevant state.
class SettingsState extends Equatable {
  /// What the user has typed in the key TextField, but not yet saved.
  final String draftKey;

  /// Whether a key is currently persisted in secure storage.
  final GeminiKeyStatus geminiKeyStatus;

  /// True while a save or clear operation is in flight.
  final bool isSaving;

  /// Non-null when the draft key failed validation or a storage error occurred.
  /// Cleared to null the moment the user changes the draft text.
  final String? errorMessage;

  /// Whether the daily review reminder notification is enabled.
  final bool reminderEnabled;

  /// The time of day at which the daily reminder fires. Defaults to 9:00 AM.
  final TimeOfDay reminderTime;

  /// True while a notification permission request or scheduling call is in flight.
  final bool isScheduling;

  /// Non-null when a notification operation (permission request or scheduling) fails.
  /// Cleared to null on the next successful notification operation.
  final String? notificationError;

  const SettingsState({
    this.draftKey = '',
    this.geminiKeyStatus = GeminiKeyStatus.unknown,
    this.isSaving = false,
    this.errorMessage,
    this.reminderEnabled = false,
    this.reminderTime = const TimeOfDay(hour: 9, minute: 0),
    this.isScheduling = false,
    this.notificationError,
  });

  /// Returns a new [SettingsState] with only the specified fields replaced.
  SettingsState copyWith({
    String? draftKey,
    GeminiKeyStatus? geminiKeyStatus,
    bool? isSaving,
    // Sentinels allow explicitly passing null to clear the nullable fields.
    Object? errorMessage = _sentinel,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    bool? isScheduling,
    Object? notificationError = _sentinel,
  }) {
    return SettingsState(
      draftKey: draftKey ?? this.draftKey,
      geminiKeyStatus: geminiKeyStatus ?? this.geminiKeyStatus,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      isScheduling: isScheduling ?? this.isScheduling,
      notificationError: notificationError == _sentinel
          ? this.notificationError
          : notificationError as String?,
    );
  }

  @override
  List<Object?> get props => [
    draftKey,
    geminiKeyStatus,
    isSaving,
    errorMessage,
    reminderEnabled,
    reminderTime,
    isScheduling,
    notificationError,
  ];
}

// Sentinel object used by copyWith to distinguish "caller passed null" from
// "caller did not pass this field". A plain null default would prevent clearing
// errorMessage back to null after a validation error.
const Object _sentinel = Object();
