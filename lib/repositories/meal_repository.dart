import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/daily_meal_log.dart';

class MealRepository {
  static const String _dailyLogsBoxName = 'daily_meal_logs';
  static const String _completionBoxName = 'meal_completions'; // Legacy box

  late Box<String> _dailyLogsBox;
  late Box<String> _completionBox;

  Future<void> init() async {
    _dailyLogsBox = await Hive.openBox<String>(_dailyLogsBoxName);
    _completionBox = await Hive.openBox<String>(_completionBoxName);
    await _migrateLegacyCompletions();
  }

  Future<void> _migrateLegacyCompletions() async {
    // If the legacy box has entries, convert them to DailyMealLog manual entries
    if (_completionBox.isNotEmpty) {
      for (final key in _completionBox.keys) {
        final date = key as String;
        final jsonStr = _completionBox.get(date);
        if (jsonStr != null) {
          try {
            final completions = jsonDecode(jsonStr) as Map<String, dynamic>;
            final existingLog = getDailyLog(date);
            
            MealSlotLog? makeDummySlot(bool isCompleted) {
              if (!isCompleted) return null;
              return MealSlotLog(
                items: [
                  MealItemLog(name: 'Legacy Log', portion: '1', calories: 350, proteinG: 0, carbsG: 0, fatG: 0)
                ],
                totalCalories: 350,
                totalProtein: 0,
                totalCarbs: 0,
                totalFat: 0,
              );
            }

            final newLog = existingLog.copyWith(
              breakfast: existingLog.breakfast ?? makeDummySlot(completions['breakfast'] == true),
              lunch: existingLog.lunch ?? makeDummySlot(completions['lunch'] == true),
              snack: existingLog.snack ?? makeDummySlot(completions['snack'] == true),
              dinner: existingLog.dinner ?? makeDummySlot(completions['dinner'] == true),
            );

            await saveDailyLog(newLog);
          } catch (_) {
            // Ignore corrupted legacy data
          }
        }
      }
      await _completionBox.clear(); // Clear so we don't migrate again
    }
  }

  DailyMealLog getDailyLog(String date) {
    final jsonStr = _dailyLogsBox.get(date);
    if (jsonStr == null) {
      return DailyMealLog(date: date);
    }
    try {
      return DailyMealLog.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return DailyMealLog(date: date);
    }
  }

  Future<void> saveDailyLog(DailyMealLog log) async {
    await _dailyLogsBox.put(log.date, jsonEncode(log.toJson()));
  }

  Future<void> saveMealSlot(String date, String slotName, MealSlotLog slotLog) async {
    final currentLog = getDailyLog(date);
    DailyMealLog updated;
    switch (slotName) {
      case 'breakfast':
        updated = currentLog.copyWith(breakfast: slotLog);
        break;
      case 'lunch':
        updated = currentLog.copyWith(lunch: slotLog);
        break;
      case 'snack':
        updated = currentLog.copyWith(snack: slotLog);
        break;
      case 'dinner':
        updated = currentLog.copyWith(dinner: slotLog);
        break;
      default:
        return;
    }
    await saveDailyLog(updated);
  }

  Future<void> clearMealSlot(String date, String slotName) async {
    final currentLog = getDailyLog(date);
    DailyMealLog updated;
    switch (slotName) {
      case 'breakfast':
        updated = currentLog.copyWith(clearBreakfast: true);
        break;
      case 'lunch':
        updated = currentLog.copyWith(clearLunch: true);
        break;
      case 'snack':
        updated = currentLog.copyWith(clearSnack: true);
        break;
      case 'dinner':
        updated = currentLog.copyWith(clearDinner: true);
        break;
      default:
        return;
    }
    await saveDailyLog(updated);
  }
}
