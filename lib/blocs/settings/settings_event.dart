// settings_event.dart
//
// Events that drive the SettingsBloc state machine.
//
// WHY THESE EVENTS EXIST:
//   Flutter BLoC mandates that UI never calls business logic directly — all
//   intent flows through events. These events model every distinct user action
//   or lifecycle trigger related to the Gemini API key workflow and the daily
//   reminder notification preference.
//
// EVENT LIFECYCLE:
//   GeminiKeyLoaded       → fired once when SettingsScreen is first built, so the
//                           bloc can hydrate from secure storage before the user
//                           interacts with anything.
//   GeminiKeyChanged      → fired on every keystroke in the key TextField.
//   GeminiKeySaved        → fired when the user taps "Save"; triggers validation.
//   GeminiKeyCleared      → fired when the user taps "Clear"; deletes the stored key.
//   NotificationPrefsLoaded → fired once on screen open to load reminder prefs.
//   ReminderToggled       → fired when the user flips the reminder switch.
//   ReminderTimeChanged   → fired when the user picks a new reminder time.

import 'package:flutter/material.dart';

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

/// Dispatched once when SettingsScreen opens to load notification preferences
/// from SharedPreferences into bloc state.
class NotificationPrefsLoaded extends SettingsEvent {}

/// Dispatched when the user toggles the "Daily reminder" switch.
///
/// If [enabled] is true and permission has not been granted, the bloc requests
/// permission before scheduling. If permission is denied, [enabled] stays false.
class ReminderToggled extends SettingsEvent {
  final bool enabled;
  ReminderToggled(this.enabled);
}

/// Dispatched when the user picks a new reminder time via the time picker.
///
/// Only has an effect when the reminder is currently enabled; the bloc
/// reschedules immediately using the new time.
class ReminderTimeChanged extends SettingsEvent {
  final TimeOfDay time;
  ReminderTimeChanged(this.time);
}

/// Dispatched when the user changes their daily card-study goal.
///
/// [goal] must be > 0. The bloc persists the new value to SharedPreferences.
class DailyGoalChanged extends SettingsEvent {
  final int goal;
  DailyGoalChanged(this.goal);
}
