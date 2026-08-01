import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/exercise_log.dart';
import '../models/exercise_pr.dart';

class ExerciseLogRepository {
  static const String _boxName = 'exercise_logs';
  static const String _prBoxName = 'exercise_prs';

  late Box<String> _box;
  late Box<String> _prBox;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    _prBox = await Hive.openBox<String>(_prBoxName);
  }

  ExercisePr? getPr(String exerciseName) {
    final jsonStr = _prBox.get(exerciseName);
    if (jsonStr == null) return null;
    return ExercisePr.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  Future<void> savePr(ExercisePr pr) async {
    await _prBox.put(pr.exerciseName, jsonEncode(pr.toJson()));
  }

  ExerciseLog? getLog(String date, String exerciseName) {
    final key = '${date}_$exerciseName';
    final jsonStr = _box.get(key);
    if (jsonStr == null) return null;
    return ExerciseLog.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  Future<void> saveLog(ExerciseLog log) async {
    await _box.put(log.key, jsonEncode(log.toJson()));
  }

  bool hasLog(String date, String exerciseName) {
    return _box.containsKey('${date}_$exerciseName');
  }

  List<ExerciseLog> getLogsForExercise(String exerciseName) {
    final logs = <ExerciseLog>[];
    for (final key in _box.keys) {
      final keyStr = key as String;
      if (keyStr.endsWith('_$exerciseName')) {
        final jsonStr = _box.get(keyStr);
        if (jsonStr != null) {
          logs.add(ExerciseLog.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>));
        }
      }
    }
    logs.sort((a, b) => a.date.compareTo(b.date));
    return logs;
  }

  List<ExerciseLog> getLogsForDate(String date) {
    final logs = <ExerciseLog>[];
    for (final key in _box.keys) {
      final keyStr = key as String;
      if (keyStr.startsWith('${date}_')) {
        final jsonStr = _box.get(keyStr);
        if (jsonStr != null) {
          logs.add(ExerciseLog.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>));
        }
      }
    }
    return logs;
  }
}
