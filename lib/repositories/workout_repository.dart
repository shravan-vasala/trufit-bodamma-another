import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/workout_plan.dart';

class WorkoutRepository {
  static const String _planBoxName = 'workout_plans';
  static const String _sessionBoxName = 'workout_sessions';

  late Box<String> _planBox;
  late Box<String> _sessionBox;

  Future<void> init() async {
    _planBox = await Hive.openBox<String>(_planBoxName);
    _sessionBox = await Hive.openBox<String>(_sessionBoxName);
    await _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    if (_planBox.isEmpty) {
      final jsonStr = await rootBundle.loadString('assets/data/seed_workout_plan.json');
      _planBox.put('beginner_plan', jsonStr);
    }
  }

  List<WorkoutPlan> getAllPlans() {
    return _planBox.values.map((jsonStr) {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WorkoutPlan.fromJson(json);
    }).toList();
  }

  WorkoutPlan? getActivePlan() {
    if (_planBox.isEmpty) return null;
    final jsonStr = _planBox.values.first;
    return WorkoutPlan.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  WorkoutDay? getWorkoutDay(String dayId) {
    final plans = getAllPlans();
    for (final plan in plans) {
      for (final day in plan.days) {
        if (day.dayId == dayId) return day;
      }
    }
    return null;
  }

  Future<void> savePlan(String key, WorkoutPlan plan) async {
    await _planBox.put(key, jsonEncode(plan.toJson()));
  }

  Future<void> savePlanJson(String key, String jsonStr) async {
    // Validate JSON first
    jsonDecode(jsonStr);
    await _planBox.put(key, jsonStr);
  }

  // Exercise completions for a workout session
  Map<String, bool> getExerciseCompletions(String date, String dayId) {
    final key = '${date}_$dayId';
    final jsonStr = _sessionBox.get(key);
    if (jsonStr == null) return {};
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    return (data['completions'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as bool)) ??
        {};
  }

  Future<void> toggleExerciseCompletion(
      String date, String dayId, String exerciseName) async {
    final key = '${date}_$dayId';
    final jsonStr = _sessionBox.get(key);
    Map<String, dynamic> data = {};
    if (jsonStr != null) {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    }
    final completions =
        (data['completions'] as Map<String, dynamic>?) ?? {};
    completions[exerciseName] = !(completions[exerciseName] as bool? ?? false);
    data['completions'] = completions;
    data['dayId'] = dayId;
    data['date'] = date;
    await _sessionBox.put(key, jsonEncode(data));
  }

  Future<void> finishWorkout(String date, String dayId) async {
    final key = '${date}_$dayId';
    final jsonStr = _sessionBox.get(key);
    Map<String, dynamic> data = {};
    if (jsonStr != null) {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    }
    data['finished'] = true;
    data['finishedAt'] = DateTime.now().toIso8601String();
    data['dayId'] = dayId;
    data['date'] = date;
    await _sessionBox.put(key, jsonEncode(data));
  }

  bool isWorkoutFinished(String date, String dayId) {
    final key = '${date}_$dayId';
    final jsonStr = _sessionBox.get(key);
    if (jsonStr == null) return false;
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    return data['finished'] as bool? ?? false;
  }

  String? getRawPlanJson(String key) {
    return _planBox.get(key);
  }

  List<String> getPlanKeys() {
    return _planBox.keys.cast<String>().toList();
  }
}
