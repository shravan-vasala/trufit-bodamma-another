import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/body_stats.dart';

class BodyStatsRepository {
  static const String _boxName = 'body_stats';

  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  BodyStats? getStats(String date) {
    final jsonStr = _box.get(date);
    if (jsonStr == null) return null;
    return BodyStats.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  Future<void> saveStats(BodyStats stats) async {
    await _box.put(stats.date, jsonEncode(stats.toJson()));
  }

  BodyStats? getLatestStats() {
    if (_box.isEmpty) return null;
    final keys = _box.keys.cast<String>().toList()..sort();
    return getStats(keys.last);
  }

  List<BodyStats> getAllStats() {
    final stats = _box.keys
        .map((key) => getStats(key as String))
        .whereType<BodyStats>()
        .toList();
    stats.sort((a, b) => a.date.compareTo(b.date));
    return stats;
  }
}
