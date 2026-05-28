// notification_prefs_keys.dart
//
// SharedPreferences keys for daily reminder preferences.
// Defined centrally so main.dart and SettingsBloc share the same keys
// without coupling to each other.

/// Whether the daily reminder notification is enabled.
const String kReminderEnabledKey = 'reminder_enabled';

/// Hour component (0–23) of the user-configured reminder time.
const String kReminderHourKey = 'reminder_hour';

/// Minute component (0–59) of the user-configured reminder time.
const String kReminderMinuteKey = 'reminder_minute';
