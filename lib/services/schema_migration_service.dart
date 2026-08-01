import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SchemaMigrationService {
  static const int currentSchemaVersion = 2;
  static const String _versionKey = 'schema_version';

  /// Run migrations for the active Hive data on application startup.
  static Future<void> runStartupMigrations(SharedPreferences prefs) async {
    final int storedVersion = prefs.getInt(_versionKey) ?? 1;

    if (storedVersion >= currentSchemaVersion) {
      return; // Already up to date
    }

    int workingVersion = storedVersion;

    if (workingVersion < 2) {
      await _migrateV1ToV2Startup();
      workingVersion = 2;
    }

    // After all migrations succeed, update the stored version
    await prefs.setInt(_versionKey, currentSchemaVersion);
  }

  /// Run migrations for in-memory backup data before writing to Hive during a restore.
  static Map<String, dynamic> runMigrationsForRestore(
    Map<String, dynamic> boxes,
    int manifestVersion,
  ) {
    if (manifestVersion >= currentSchemaVersion) {
      return boxes;
    }

    int workingVersion = manifestVersion;

    if (workingVersion < 2) {
      _migrateV1ToV2Restore(boxes);
      workingVersion = 2;
    }

    return boxes;
  }

  // ─── Migrations V1 -> V2 ───────────────────────────────────────────────────
  
  static Future<void> _migrateV1ToV2Startup() async {
    final box = await Hive.openBox<String>('user_profile');
    final jsonStr = box.get('profile');
    if (jsonStr != null) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      _applyV2UserProfileChanges(map);
      await box.put('profile', jsonEncode(map));
    }
  }

  static void _migrateV1ToV2Restore(Map<String, dynamic> boxes) {
    if (boxes.containsKey('user_profile')) {
      final boxData = boxes['user_profile'] as Map<String, dynamic>;
      if (boxData.containsKey('profile')) {
        final map = jsonDecode(boxData['profile'].toString()) as Map<String, dynamic>;
        _applyV2UserProfileChanges(map);
        boxData['profile'] = jsonEncode(map);
      }
    }
  }

  static void _applyV2UserProfileChanges(Map<String, dynamic> map) {
    map.putIfAbsent('targetProteinG', () => 120);
    map.putIfAbsent('targetCarbsG', () => 150);
    map.putIfAbsent('targetFatG', () => 50);
    if (!map.containsKey('planStartDate')) {
      map['planStartDate'] = null;
    }
    map.putIfAbsent('currentPhaseWeek', () => 1);
    map.putIfAbsent('restTimerSound', () => true);
    map.putIfAbsent('restTimerVibration', () => true);
  }
}
