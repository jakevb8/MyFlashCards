// settings_event.dart
//
// Events that drive the SettingsBloc state machine.
//
// WHY THESE EVENTS EXIST:
//   Flutter BLoC mandates that UI never calls business logic directly — all
//   intent flows through events. These events model every distinct user action
//   or lifecycle trigger related to the Gemini API key workflow.
//
// EVENT LIFECYCLE:
//   GeminiKeyLoaded  → fired once when SettingsScreen is first built, so the
//                       bloc can hydrate from secure storage before the user
//                       interacts with anything.
//   GeminiKeyChanged → fired on every keystroke in the key TextField, keeping
//                       the draft in sync without hitting storage.
//   GeminiKeySaved   → fired when the user taps "Save"; triggers validation
//                       and, if valid, persists to secure storage.
//   GeminiKeyCleared → fired when the user taps "Clear"; deletes the stored key.

/// Base class for all settings-related BLoC events.
abstract class SettingsEvent {}

/// Dispatched when the user edits the API key text field.
///
/// [key] is the raw current text — may be incomplete or invalid.
class GeminiKeyChanged extends SettingsEvent {
  final String key;
  GeminiKeyChanged(this.key);
}

/// Dispatched when the user taps the "Save" button in the key bottom sheet.
///
/// The bloc validates the draft key before persisting it.
class GeminiKeySaved extends SettingsEvent {}

/// Dispatched when the user taps the "Clear" button in the key bottom sheet.
///
/// Deletes the stored key and resets draft state.
class GeminiKeyCleared extends SettingsEvent {}

/// Dispatched once during SettingsBloc initialisation to hydrate state from
/// secure storage without requiring the user to interact first.
class GeminiKeyLoaded extends SettingsEvent {}
