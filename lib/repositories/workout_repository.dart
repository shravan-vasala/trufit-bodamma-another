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
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Root JSON must be an object');
    }
    final map = decoded;
    
    if (map['planName'] == null || map['planName'].toString().trim().isEmpty) {
      throw const FormatException('Missing or empty "planName"');
    }
    
    final days = map['days'];
    if (days is! List) {
      throw const FormatException('"days" must be an array');
    }
    
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      if (day is! Map<String, dynamic>) {
        throw FormatException('Day at index $i is not an object');
      }
      
      final exercises = day['exercises'];
      if (exercises != null && exercises is! List) {
        throw FormatException('"exercises" in day "${day['dayName'] ?? 'unknown'}" must be an array');
      }
      
      if (exercises != null) {
        for (final ex in exercises) {
          if (ex is! Map<String, dynamic>) {
            throw const FormatException('Each exercise must be an object');
          }
          final name = ex['name']?.toString() ?? '';
          if (name.trim().isEmpty) {
            throw const FormatException('An exercise is missing a "name"');
          }
          final reps = ex['reps']?.toString() ?? '';
          if (reps.trim().isEmpty) {
            throw FormatException('Exercise "$name" is missing "reps"');
          }
          
          final yt = ex['youtubeUrl']?.toString() ?? '';
          if (yt.isNotEmpty) {
            if (!yt.contains('youtube.com/watch') && !yt.contains('youtu.be')) {
              throw FormatException('Invalid YouTube URL format for exercise "$name". Use youtube.com/watch or youtu.be');
            }
          }
        }
      }
    }
    
    await _planBox.put(key, jsonStr);
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
