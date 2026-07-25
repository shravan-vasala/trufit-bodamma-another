import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/daily_log.dart';

class DailyLogRepository {
  static const String _boxName = 'daily_logs';

  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  DailyLog? getLog(String date) {
    final jsonStr = _box.get(date);
    if (jsonStr == null) return null;
    return DailyLog.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  DailyLog getOrCreate(String date) {
    return getLog(date) ?? DailyLog(date: date);
  }

  Future<void> saveLog(DailyLog log) async {
    await _box.put(log.date, jsonEncode(log.toJson()));
  }

  Future<void> updateWeight(String date, double weight) async {
    final log = getOrCreate(date);
    await saveLog(log.copyWith(weight: weight));
  }

  Future<void> updateSteps(String date, int steps, {String? source}) async {
    final log = getOrCreate(date);
    await saveLog(log.copyWith(steps: steps, stepsSource: source));
  }

  Future<void> updateSleep(String date, double? hours, {String? source}) async {
    final log = getOrCreate(date);
    await saveLog(log.copyWith(
      sleepHours: hours,
      sleepSource: source,
    ));
  }

  Future<void> clearSleep(String date) async {
    final log = getOrCreate(date);
    await saveLog(log.clearSleep());
  }

  Future<void> updateBodyFat(String date, double bodyFat) async {
    final log = getOrCreate(date);
    await saveLog(log.copyWith(bodyFat: bodyFat));
  }

  Future<void> markWorkoutCompleted(String date, String dayId) async {
    final log = getOrCreate(date);
    await saveLog(log.copyWith(workoutCompleted: true, workoutDayId: dayId));
  }

  List<DailyLog> getLogsInRange(String startDate, String endDate) {
    final logs = <DailyLog>[];
    for (final key in _box.keys) {
      final dateKey = key as String;
      if (dateKey.compareTo(startDate) >= 0 && dateKey.compareTo(endDate) <= 0) {
        final log = getLog(dateKey);
        if (log != null) logs.add(log);
      }
    }
    logs.sort((a, b) => a.date.compareTo(b.date));
    return logs;
  }

  List<DailyLog> getAllLogs() {
    final logs = _box.keys.map((key) => getLog(key as String)).whereType<DailyLog>().toList();
    logs.sort((a, b) => a.date.compareTo(b.date));
    return logs;
  }

  bool hasActivityOnDate(String date) {
    final log = getLog(date);
    return log?.hasAnyActivity ?? false;
  }
}
