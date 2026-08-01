import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_config.dart';
import '../services/notification_service.dart';
import 'app_providers.dart';
import 'package:flutter/material.dart';

class RemindersNotifier extends StateNotifier<ReminderConfig> {
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  final Ref _ref;

  RemindersNotifier(this._prefs, this._notificationService, this._ref) : super(ReminderConfig()) {
    _load();
  }

  static const _key = 'reminder_config';

  void _load() {
    final jsonStr = _prefs.getString(_key);
    if (jsonStr != null) {
      state = ReminderConfig.fromJson(jsonStr);
    }
  }

  Future<void> updateConfig(ReminderConfig newConfig) async {
    state = newConfig;
    await _prefs.setString(_key, newConfig.toJson());
    await _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    // Request permission if enabling anything
    if (state.habitsEnabled || state.workoutsEnabled || state.mealsEnabled || state.backupEnabled) {
      final granted = await _notificationService.requestPermissions();
      if (!granted) {
        // Fallback: If not granted, we probably shouldn't keep them enabled in UI
        // But we'll let it be for now and let the user see them toggled but not firing.
      }
    }

    await _notificationService.cancelAll();

    if (state.habitsEnabled) {
      await _notificationService.scheduleHabitReminder(state.habitTime);
    }

    if (state.workoutsEnabled) {
      final workoutPlan = _ref.read(workoutPlanProvider);
      if (workoutPlan != null) {
        // Convert active days to list of ints (1=Monday, 7=Sunday)
        // workoutPlan.days has items. Index 0 is Monday (usually)
        List<int> activeDays = [];
        for (int i = 0; i < workoutPlan.days.length; i++) {
          if (workoutPlan.days[i].sections.isNotEmpty && workoutPlan.days[i].dayId != 'Rest') {
            activeDays.add(i + 1); // 1 to 6
          }
        }
        if (activeDays.isNotEmpty) {
          await _notificationService.scheduleWorkoutReminders(activeDays, state.workoutTime);
        }
      }
    }

    if (state.mealsEnabled) {
      await _notificationService.scheduleMealReminders(state.lunchTime, state.dinnerTime);
    }

    if (state.backupEnabled) {
      await _notificationService.scheduleBackupReminder(state.backupDayOfWeek, state.backupTime);
    }
  }

  // Called on app boot from main.dart
  Future<void> initializeNotifications() async {
    await _syncNotifications();
  }
}

final remindersProvider = StateNotifierProvider<RemindersNotifier, ReminderConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return RemindersNotifier(prefs, notificationService, ref);
});

// Assuming sharedPreferencesProvider exists in app_providers.dart or similar.
// If it doesn't, we will provide it in main.dart:
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('prefs must be overridden in ProviderScope');
});
