import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/habit.dart';

class HabitRepository {
  static const String _configBoxName = 'habit_config';
  static const String _completionBoxName = 'habit_completions';

  late Box<String> _configBox;
  late Box<String> _completionBox;

  Future<void> init() async {
    _configBox = await Hive.openBox<String>(_configBoxName);
    _completionBox = await Hive.openBox<String>(_completionBoxName);
    await _seedIfEmpty();
    await _migrateLegacyConfig();
  }

  Future<void> _seedIfEmpty() async {
    if (_configBox.isEmpty) {
      final defaultHabits = Habit.defaults;
      for (final habit in defaultHabits) {
        await _configBox.put(habit.id, jsonEncode(habit.toJson()));
      }
    }
  }

  Future<void> _migrateLegacyConfig() async {
    // Check if the 'sleep' habit is legacy (missing 'type' field in JSON)
    final sleepStr = _configBox.get('sleep');
    if (sleepStr != null) {
      final map = jsonDecode(sleepStr) as Map<String, dynamic>;
      if (map['type'] == null) {
        // Run migration for old defaults
        for (final defaultHabit in Habit.defaults) {
          final existingStr = _configBox.get(defaultHabit.id);
          if (existingStr != null) {
            final oldMap = jsonDecode(existingStr) as Map<String, dynamic>;
            final old = Habit.fromJson(oldMap);
            // We want to force the new types and targets for legacy items, 
            // but keep any custom name/icon the user might have somehow set.
            final migrated = old.copyWith(
              type: defaultHabit.type,
              target: defaultHabit.target,
              step: defaultHabit.step,
              unit: defaultHabit.unit,
              order: defaultHabit.order,
            );
            await saveHabit(migrated);
          }
        }
      }
    }
  }

  List<Habit> getHabits() {
    final habits = _configBox.values.map((jsonStr) {
      return Habit.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }).toList();
    habits.sort((a, b) => a.order.compareTo(b.order));
    return habits;
  }

  Future<void> saveHabit(Habit habit) async {
    await _configBox.put(habit.id, jsonEncode(habit.toJson()));
  }

  Future<void> deleteHabit(String id) async {
    await _configBox.delete(id);
  }

  Future<void> reorderHabits(List<Habit> reordered) async {
    for (int i = 0; i < reordered.length; i++) {
      final h = reordered[i].copyWith(order: i);
      await saveHabit(h);
    }
  }

  HabitCompletion getCompletions(String date) {
    final jsonStr = _completionBox.get(date);
    if (jsonStr == null) return HabitCompletion(date: date);
    return HabitCompletion.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  Future<void> saveCompletion(HabitCompletion completion) async {
    await _completionBox.put(completion.date, jsonEncode(completion.toJson()));
  }

  // Checkbox toggle
  Future<void> toggleCheckboxCompletion(String date, String habitId) async {
    final completion = getCompletions(date);
    final updated = completion.toggleCheckbox(habitId);
    await saveCompletion(updated);
  }

  // Counter / numeric update
  Future<void> updateProgress(String date, String habitId, double progress) async {
    final completion = getCompletions(date);
    final updated = completion.updateProgress(habitId, progress);
    await saveCompletion(updated);
  }

  // Backwards compatibility for old HealthConnectService code
  Future<void> setCompletion(String date, String habitId, dynamic completed) async {
    final completion = getCompletions(date);
    final current = completion.completions[habitId];
    if (current == completed) return; 

    final newCompletions = Map<String, dynamic>.from(completion.completions);
    newCompletions[habitId] = completed;
    final updated = HabitCompletion(date: date, completions: newCompletions, overrides: completion.overrides);
    await saveCompletion(updated);
  }

  Future<void> setOverride(String date, String habitId, String? overrideValue) async {
    final completion = getCompletions(date);
    final updated = completion.setOverride(habitId, overrideValue);
    await saveCompletion(updated);
  }
}
