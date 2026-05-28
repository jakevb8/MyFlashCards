// settings_bloc.dart
//
// BLoC that manages the Gemini API key and daily reminder preferences within
// the Settings screen.
//
// STATE MACHINE OVERVIEW:
//
//   Initial: GeminiKeyStatus.unknown, draftKey='', isSaving=false,
//            reminderEnabled=false, reminderTime=9:00, isScheduling=false
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
//   NotificationPrefsLoaded
//     → reads reminderEnabled, reminderTime from SharedPreferences
//     → emits updated state; no scheduling occurs here (prefs only)
//
//   ReminderToggled(enabled)
//     → if enabling:
//         isScheduling=true → requestPermission()
//         if denied: emits reminderEnabled=false, notificationError, isScheduling=false
//         if granted: countDueCards → scheduleDailyReminder → persist → reminderEnabled=true
//     → if disabling:
//         isScheduling=true → cancelDailyReminder → persist → reminderEnabled=false
//
//   ReminderTimeChanged(time)
//     → no-op when reminderEnabled=false (time stored but not scheduled)
//     → if enabled: countDueCards → scheduleDailyReminder → persist → emits new time
//
// WHY THE BLOC OWNS VALIDATION:
//   Validation logic (AIza prefix, length) is a business rule, not a UI rule.
//   Keeping it here means tests can exercise it without spinning up widgets.
//
// WHY WE DON'T STORE THE KEY IN STATE:
//   The actual key value should not live in the BLoC state — state can be
//   logged, replayed in tests, or accidentally printed. We only store the
//   draft (transient) and a boolean status for what's persisted.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/notification_prefs_keys.dart';
import '../../repositories/hive_flashcard_repository.dart';
import '../../services/gemini_key_service.dart';
import '../../services/notification_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// Minimum length for a Google AI Studio API key (real keys are 39 chars).
const _kMinKeyLength = 39;

/// All Google AI Studio API keys start with this prefix.
const _kKeyPrefix = 'AIza';

/// BLoC that manages reading, validating, and persisting the Gemini API key
/// and the daily review reminder notification preference.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GeminiKeyService _keyService;
  final NotificationService _notificationService;
  final HiveFlashcardRepository _cardRepo;

  SettingsBloc({
    GeminiKeyService? keyService,
    NotificationService? notificationService,
    HiveFlashcardRepository? cardRepo,
  }) : _keyService = keyService ?? GeminiKeyService(),
       _notificationService = notificationService ?? NotificationService(),
       _cardRepo = cardRepo ?? HiveFlashcardRepository(),
       super(const SettingsState()) {
    on<GeminiKeyLoaded>(_onLoaded);
    on<GeminiKeyChanged>(_onChanged);
    on<GeminiKeySaved>(_onSaved);
    on<GeminiKeyCleared>(_onCleared);
    on<NotificationPrefsLoaded>(_onNotificationPrefsLoaded);
    on<ReminderToggled>(_onReminderToggled);
    on<ReminderTimeChanged>(_onReminderTimeChanged);
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

  /// Loads notification preferences from SharedPreferences into state.
  ///
  /// Called once when the Settings screen opens. Does not schedule anything —
  /// just reflects the stored preference into the bloc so the UI can render
  /// the correct toggle and time values.
  Future<void> _onNotificationPrefsLoaded(
    NotificationPrefsLoaded event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(kReminderEnabledKey) ?? false;
    final hour = prefs.getInt(kReminderHourKey) ?? 9;
    final minute = prefs.getInt(kReminderMinuteKey) ?? 0;
    emit(
      state.copyWith(
        reminderEnabled: enabled,
        reminderTime: TimeOfDay(hour: hour, minute: minute),
      ),
    );
  }

  /// Toggles the daily reminder on or off.
  ///
  /// Enabling: requests permission, counts due cards, schedules the notification,
  /// and persists the preference. If permission is denied the reminder stays off
  /// and a [notificationError] is emitted for the UI to surface.
  ///
  /// Disabling: cancels the scheduled notification and persists the preference.
  Future<void> _onReminderToggled(
    ReminderToggled event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isScheduling: true, notificationError: null));
    try {
      if (event.enabled) {
        final granted = await _notificationService.requestPermission();
        if (!granted) {
          emit(
            state.copyWith(
              isScheduling: false,
              reminderEnabled: false,
              notificationError:
                  'Permission denied. Enable notifications in system Settings.',
            ),
          );
          return;
        }
        final dueCount = await _cardRepo.countDueCards();
        await _notificationService.scheduleDailyReminder(
          time: state.reminderTime,
          dueCount: dueCount,
        );
        await _persistReminderPrefs(enabled: true, time: state.reminderTime);
        emit(
          state.copyWith(
            reminderEnabled: true,
            isScheduling: false,
            notificationError: null,
          ),
        );
      } else {
        await _notificationService.cancelDailyReminder();
        await _persistReminderPrefs(enabled: false, time: state.reminderTime);
        emit(state.copyWith(reminderEnabled: false, isScheduling: false));
      }
    } on NotificationServiceException catch (e) {
      emit(state.copyWith(isScheduling: false, notificationError: e.message));
    }
  }

  /// Updates the reminder time and reschedules if the reminder is currently on.
  ///
  /// Always persists the new time so that when the reminder is later enabled it
  /// uses the user's chosen time rather than the default.
  Future<void> _onReminderTimeChanged(
    ReminderTimeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(reminderTime: event.time));
    await _persistReminderPrefs(
      enabled: state.reminderEnabled,
      time: event.time,
    );
    if (!state.reminderEnabled) return;
    try {
      final dueCount = await _cardRepo.countDueCards();
      await _notificationService.scheduleDailyReminder(
        time: event.time,
        dueCount: dueCount,
      );
    } on NotificationServiceException catch (e) {
      emit(state.copyWith(notificationError: e.message));
    }
  }

  /// Persists reminder preferences to SharedPreferences.
  Future<void> _persistReminderPrefs({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kReminderEnabledKey, enabled);
    await prefs.setInt(kReminderHourKey, time.hour);
    await prefs.setInt(kReminderMinuteKey, time.minute);
  }
}
