import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../models/daily_log.dart';
import '../models/exercise_log.dart';
import '../models/habit.dart';
import '../models/body_stats.dart';
import '../models/daily_meal_log.dart';

class CsvExportService {
  Future<String?> exportData(DateTime? startDate) async {
    try {
      final archive = Archive();

      // 1. Export Daily Logs
      final dailyLogsCsv = await _exportDailyLogs(startDate);
      if (dailyLogsCsv != null) {
        archive.addFile(ArchiveFile('daily_logs.csv', dailyLogsCsv.length, utf8.encode(dailyLogsCsv)));
      }

      // 2. Export Exercise Logs
      final exerciseLogsCsv = await _exportExerciseLogs(startDate);
      if (exerciseLogsCsv != null) {
        archive.addFile(ArchiveFile('exercise_logs.csv', exerciseLogsCsv.length, utf8.encode(exerciseLogsCsv)));
      }

      // 3. Export Habit Completions
      final habitsCsv = await _exportHabitCompletions(startDate);
      if (habitsCsv != null) {
        archive.addFile(ArchiveFile('habits.csv', habitsCsv.length, utf8.encode(habitsCsv)));
      }

      // 4. Export Body Stats
      final bodyStatsCsv = await _exportBodyStats(startDate);
      if (bodyStatsCsv != null) {
        archive.addFile(ArchiveFile('body_stats.csv', bodyStatsCsv.length, utf8.encode(bodyStatsCsv)));
      }

      // 5. Export Meals
      final mealsCsv = await _exportMeals(startDate);
      if (mealsCsv != null) {
        archive.addFile(ArchiveFile('meals.csv', mealsCsv.length, utf8.encode(mealsCsv)));
      }

      // Encode archive
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      if (zipData == null) return null;

      // Save to temp dir
      final tempDir = await getTemporaryDirectory();
      final fileName = 'trufit_export_${DateTime.now().millisecondsSinceEpoch}.zip';
      final zipFile = File('${tempDir.path}/$fileName');
      await zipFile.writeAsBytes(zipData);

      return zipFile.path;
    } catch (e) {
      print('Export error: $e');
      return null;
    }
  }

  bool _isAfterStartDate(String dateStr, DateTime? startDate) {
    if (startDate == null) return true;
    try {
      final date = DateTime.parse(dateStr);
      return date.isAfter(startDate.subtract(const Duration(days: 1)));
    } catch (_) {
      return false;
    }
  }

  Future<String?> _exportDailyLogs(DateTime? startDate) async {
    final box = await Hive.openBox<String>('daily_logs');
    final rows = <List<dynamic>>[];
    
    // Headers
    rows.add(['Date', 'Weight', 'Steps', 'Steps Source', 'Sleep Hours', 'Sleep Source', 'Body Fat', 'Workout Completed', 'Workout Day ID']);

    for (final key in box.keys) {
      final val = box.get(key);
      if (val == null) continue;
      try {
        final log = DailyLog.fromJson(jsonDecode(val));
        if (!_isAfterStartDate(log.date, startDate)) continue;

        rows.add([
          log.date,
          log.weight ?? '',
          log.steps ?? '',
          log.stepsSource ?? '',
          log.sleepHours ?? '',
          log.sleepSource ?? '',
          log.bodyFat ?? '',
          log.workoutCompleted,
          log.workoutDayId ?? '',
        ]);
      } catch (_) {}
    }

    if (rows.length == 1) return null; // Only headers
    return csv.encode(rows);
  }

  Future<String?> _exportExerciseLogs(DateTime? startDate) async {
    final box = await Hive.openBox<String>('exercise_logs');
    final rows = <List<dynamic>>[];
    
    rows.add(['Date', 'Exercise', 'Set', 'Reps', 'Weight']);

    for (final key in box.keys) {
      final val = box.get(key);
      if (val == null) continue;
      try {
        final log = ExerciseLog.fromJson(jsonDecode(val));
        if (!_isAfterStartDate(log.date, startDate)) continue;

        for (final set in log.sets) {
          rows.add([
            log.date,
            log.exerciseName,
            set.setNumber,
            set.reps,
            set.weight,
          ]);
        }
      } catch (_) {}
    }

    if (rows.length == 1) return null;
    return csv.encode(rows);
  }

  Future<String?> _exportHabitCompletions(DateTime? startDate) async {
    final box = await Hive.openBox<String>('habit_completions');
    final habitBox = await Hive.openBox<String>('habit_config');
    
    final habits = <String, Habit>{};
    for (final hKey in habitBox.keys) {
      try {
        final h = Habit.fromJson(jsonDecode(habitBox.get(hKey)!));
        habits[h.id] = h;
      } catch (_) {}
    }

    final rows = <List<dynamic>>[];
    rows.add(['Date', 'Habit ID', 'Habit Name', 'Value', 'Override']);

    for (final key in box.keys) {
      final val = box.get(key);
      if (val == null) continue;
      try {
        final completion = HabitCompletion.fromJson(jsonDecode(val));
        if (!_isAfterStartDate(completion.date, startDate)) continue;

        for (final entry in completion.completions.entries) {
          final habitId = entry.key;
          final habitName = habits[habitId]?.name ?? habitId;
          final val = entry.value;
          final override = completion.overrides[habitId] ?? '';
          
          rows.add([
            completion.date,
            habitId,
            habitName,
            val,
            override,
          ]);
        }
      } catch (_) {}
    }

    if (rows.length == 1) return null;
    return csv.encode(rows);
  }

  Future<String?> _exportBodyStats(DateTime? startDate) async {
    final box = await Hive.openBox<String>('body_stats');
    final rows = <List<dynamic>>[];
    
    rows.add(['Date', 'Unit', 'Waist', 'Hips', 'Chest', 'Left Arm', 'Right Arm', 'Left Thigh', 'Right Thigh', 'Neck']);

    for (final key in box.keys) {
      final val = box.get(key);
      if (val == null) continue;
      try {
        final stats = BodyStats.fromJson(jsonDecode(val));
        if (!_isAfterStartDate(stats.date, startDate)) continue;

        rows.add([
          stats.date,
          stats.unit,
          stats.waist ?? '',
          stats.hips ?? '',
          stats.chest ?? '',
          stats.leftArm ?? '',
          stats.rightArm ?? '',
          stats.leftThigh ?? '',
          stats.rightThigh ?? '',
          stats.neck ?? '',
        ]);
      } catch (_) {}
    }

    if (rows.length == 1) return null;
    return csv.encode(rows);
  }

  Future<String?> _exportMeals(DateTime? startDate) async {
    final box = await Hive.openBox<String>('daily_meal_logs');
    final rows = <List<dynamic>>[];
    
    rows.add(['Date', 'Slot', 'Total Calories', 'Total Protein (g)', 'Total Carbs (g)', 'Total Fat (g)']);

    for (final key in box.keys) {
      final val = box.get(key);
      if (val == null) continue;
      try {
        final log = DailyMealLog.fromJson(jsonDecode(val));
        if (!_isAfterStartDate(log.date, startDate)) continue;

        for (final entry in log.customSlots.entries) {
          final slotName = entry.key;
          final slot = entry.value;
          
          if (slot.totalCalories > 0 || slot.items.isNotEmpty) {
            rows.add([
              log.date,
              slotName,
              slot.totalCalories,
              slot.totalProtein,
              slot.totalCarbs,
              slot.totalFat,
            ]);
          }
        }
      } catch (_) {}
    }

    if (rows.length == 1) return null;
    return csv.encode(rows);
  }
}
