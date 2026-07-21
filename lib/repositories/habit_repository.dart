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
  }

  Future<void> _seedIfEmpty() async {
    if (_configBox.isEmpty) {
      final defaultHabits = Habit.defaults;
      for (final habit in defaultHabits) {
        await _configBox.put(habit.id, jsonEncode(habit.toJson()));
      }
    }
  }

  List<Habit> getHabits() {
    return _configBox.values.map((jsonStr) {
      return Habit.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }).toList();
  }

  Future<void> saveHabit(Habit habit) async {
    await _configBox.put(habit.id, jsonEncode(habit.toJson()));
  }

  Future<void> deleteHabit(String id) async {
    await _configBox.delete(id);
  }

  HabitCompletion getCompletions(String date) {
    final jsonStr = _completionBox.get(date);
    if (jsonStr == null) return HabitCompletion(date: date);
    return HabitCompletion.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  Future<void> toggleCompletion(String date, String habitId) async {
    final completion = getCompletions(date);
    final updated = completion.toggle(habitId);
    await _completionBox.put(date, jsonEncode(updated.toJson()));
  }

  int getCompletedCount(String date) {
    return getCompletions(date).completedCount;
  }
}
