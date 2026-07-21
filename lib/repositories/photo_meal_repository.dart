import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scanned_meal_log.dart';

class PhotoMealRepository {
  static const String _boxName = 'scanned_photo_meals';

  late Box<String> _box;
  late String _baseDir;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = '${appDir.path}/trufit_meal_photos';
    await Directory(_baseDir).create(recursive: true);
  }

  Future<ScannedMealLog> saveScannedMeal({
    required String date,
    required String sourcePhotoPath,
    required String mealType,
    required String foodName,
    required int estimatedCalories,
    required double proteinGrams,
    required double carbsGrams,
    required double fatGrams,
    required double portionMultiplier,
  }) async {
    final timestampMs = DateTime.now().millisecondsSinceEpoch;
    final ext = sourcePhotoPath.split('.').last;
    final destPath = '$_baseDir/${date}_$timestampMs.$ext';
    await File(sourcePhotoPath).copy(destPath);

    final log = ScannedMealLog(
      id: 'photo_meal_$timestampMs',
      date: date,
      photoPath: destPath,
      mealType: mealType,
      foodName: foodName,
      estimatedCalories: estimatedCalories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      portionMultiplier: portionMultiplier,
      timestamp: DateTime.now().toIso8601String(),
    );

    await _box.put(log.id, jsonEncode(log.toJson()));
    return log;
  }

  List<ScannedMealLog> getScannedMealsForDate(String date) {
    final logs = <ScannedMealLog>[];
    for (final jsonStr in _box.values) {
      final log = ScannedMealLog.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      if (log.date == date) {
        logs.add(log);
      }
    }
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  int getTotalScannedCaloriesForDate(String date) {
    final meals = getScannedMealsForDate(date);
    return meals.fold(0, (sum, m) => sum + m.totalCalories);
  }

  Future<void> deleteScannedMeal(String id) async {
    final jsonStr = _box.get(id);
    if (jsonStr != null) {
      final log = ScannedMealLog.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      final file = File(log.photoPath);
      if (await file.exists()) {
        await file.delete();
      }
      await _box.delete(id);
    }
  }
}
