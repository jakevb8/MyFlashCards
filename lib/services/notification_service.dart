// notification_service.dart
//
// Wraps flutter_local_notifications to schedule and cancel the single daily
// review reminder notification.
//
// Responsibilities:
//   - Initialise the notification plugin once at app startup.
//   - Request OS-level notification permission when the user first enables
//     reminders (iOS always; Android 13+ POST_NOTIFICATIONS runtime permission).
//   - Schedule a daily notification at a user-chosen time with a due-card count.
//   - Cancel the existing notification (e.g. after a study session completes).
//
// Invariants:
//   - All scheduled notifications use the fixed ID [_kDailyReminderNotificationId]
//     so that re-scheduling always replaces the previous notification, never
//     stacks up duplicates.
//   - Timezone-aware scheduling (tz.local) ensures "9:00 AM" fires at 9:00 in
//     the user's local timezone even across DST changes.
//   - This class does NOT own preference storage — SettingsBloc and main.dart
//     read/write SharedPreferences and pass the relevant values here.

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/flashcard.dart';

/// Notification channel identifiers — must be stable across app updates.
const int _kDailyReminderNotificationId = 1;
const String _kChannelId = 'daily_reminder';
const String _kChannelName = 'Daily Review Reminder';
const String _kChannelDescription =
    'Reminds you to study your due flashcards each day.';

/// Thrown when a notification plugin call fails.
class NotificationServiceException implements Exception {
  final String message;
  const NotificationServiceException(this.message);

  @override
  String toString() => 'NotificationServiceException: $message';
}

/// Service responsible for scheduling and cancelling the daily review reminder.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initialises the notification plugin and timezone database.
  ///
  /// Must be called once before any other method. Safe to call multiple times
  /// (subsequent calls are no-ops via the plugin's internal init guard). Errors
  /// are wrapped in [NotificationServiceException].
  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        // Permissions are requested lazily at toggle time, not at init.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _plugin.initialize(settings);
    } catch (e) {
      throw NotificationServiceException('Failed to initialise: $e');
    }
  }

  /// Requests OS notification permission from the user.
  ///
  /// On iOS, shows the system permission dialog. On Android 13+ (API 33+),
  /// requests the POST_NOTIFICATIONS runtime permission. Returns `true` when
  /// permission is granted, `false` when denied.
  Future<bool> requestPermission() async {
    try {
      // iOS
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        );
        return granted ?? false;
      }

      // Android 13+
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }

      // Older Android — permission is granted at install time.
      return true;
    } catch (e) {
      throw NotificationServiceException('Permission request failed: $e');
    }
  }

  /// Schedules (or reschedules) a daily notification at [time].
  ///
  /// The notification body reads "You have [dueCount] cards due today". Cancels
  /// any previously scheduled reminder before scheduling the new one so there is
  /// never more than one pending notification with [_kDailyReminderNotificationId].
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required int dueCount,
  }) async {
    try {
      // Always cancel first to replace any existing schedule.
      await _plugin.cancel(_kDailyReminderNotificationId);

      final scheduledDate = _nextInstanceOfTime(time);

      const androidDetails = AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final body = dueCount == 0
          ? "You're all caught up! Great work."
          : dueCount == 1
          ? 'You have 1 card due today.'
          : 'You have $dueCount cards due today.';

      await _plugin.zonedSchedule(
        _kDailyReminderNotificationId,
        'MyFlashCards',
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // absoluteTime ensures the notification fires at the exact scheduled
        // time rather than being adjusted for the user's clock setting.
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      throw NotificationServiceException('Failed to schedule reminder: $e');
    }
  }

  /// Cancels the daily reminder if one is pending.
  Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(_kDailyReminderNotificationId);
    } catch (e) {
      throw NotificationServiceException('Failed to cancel reminder: $e');
    }
  }

  /// Returns the count of non-archived flashcards that are due today.
  ///
  /// A card is due when [Flashcard.nextReviewAt] is null (new card, never
  /// reviewed) or is not after the current moment. Archived cards are excluded.
  int countDueCards(List<Flashcard> allCards) {
    final now = DateTime.now();
    return allCards
        .where(
          (c) =>
              !c.archived &&
              (c.nextReviewAt == null || !c.nextReviewAt!.isAfter(now)),
        )
        .length;
  }

  /// Returns the next [TZDateTime] matching [time] in the device's local timezone.
  ///
  /// If [time] has already passed today, the schedule targets the same time
  /// tomorrow. This prevents an immediate notification when the user sets a
  /// reminder for a time that already passed.
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
