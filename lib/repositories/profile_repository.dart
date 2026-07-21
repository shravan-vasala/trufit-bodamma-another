import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  static const String _boxName = 'user_profile';
  static const String _profileKey = 'profile';

  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    if (!_box.containsKey(_profileKey)) {
      await saveProfile(UserProfile());
    }
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
