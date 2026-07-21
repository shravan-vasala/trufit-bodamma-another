import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/exercise_log.dart';

class ExerciseLogRepository {
  static const String _boxName = 'exercise_logs';

  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
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
