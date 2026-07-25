import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  static const String _boxName = 'user_profile';
  static const String _profileKey = 'profile';

  late Box<String> _box;
  final _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    if (!_box.containsKey(_profileKey)) {
      await saveProfile(UserProfile());
    } else {
      // Migration: strip geminiApiKey from stored JSON
      final jsonStr = _box.get(_profileKey)!;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (map.containsKey('geminiApiKey')) {
        final key = map['geminiApiKey'] as String?;
        if (key != null && key.isNotEmpty) {
          await saveSecureGeminiKey(key);
        }
        map.remove('geminiApiKey');
        await _box.put(_profileKey, jsonEncode(map));
      }
    }
  }

  Future<String?> getSecureGeminiKey() async {
    return await _secureStorage.read(key: 'gemini_api_key');
  }

  Future<void> saveSecureGeminiKey(String key) async {
    await _secureStorage.write(key: 'gemini_api_key', value: key);
  }

  UserProfile getProfile() {
    final jsonStr = _box.get(_profileKey);
    if (jsonStr == null) return UserProfile();
    return UserProfile.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _box.put(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> updateName(String name) async {
    final profile = getProfile();
    await saveProfile(profile.copyWith(name: name));
  }

  Future<void> updateHeight(double height) async {
    final profile = getProfile();
    await saveProfile(profile.copyWith(height: height));
  }

  Future<void> updateTargetWeight(double weight) async {
    final profile = getProfile();
    await saveProfile(profile.copyWith(targetWeight: weight));
  }

  Future<void> toggleUnit() async {
    final profile = getProfile();
    await saveProfile(profile.copyWith(useKg: !profile.useKg));
  }
}
