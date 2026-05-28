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

/// Daily card-study goal (integer). Default: 10.
const String kDailyGoalKey = 'daily_goal';

// ── Milestone seen flags ───────────────────────────────────────────────────
// Set to true once each milestone has been celebrated. Prevents re-triggering
// confetti for the same milestone on every subsequent session.

/// User completed their first ever study session.
const String kMilestoneFirstSession = 'milestone_first_session';

/// User hit a 7-day study streak.
const String kMilestoneStreak7 = 'milestone_streak_7';

/// User hit a 30-day study streak.
const String kMilestoneStreak30 = 'milestone_streak_30';

/// User reviewed 50 cards in total (all-time).
const String kMilestoneCards50 = 'milestone_cards_50';

/// User reviewed 100 cards in total (all-time).
const String kMilestoneCards100 = 'milestone_cards_100';

/// User hit their daily goal for the first time.
const String kMilestoneDailyGoal = 'milestone_daily_goal';
