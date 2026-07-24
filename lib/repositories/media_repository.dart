import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class MediaRepository {
  static const String _boxName = 'media_metadata';

  late Box<String> _box;
  late String _baseDir;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      _baseDir = '${appDir.path}/trufit_media';
      await Directory(_baseDir).create(recursive: true);
      await Directory('$_baseDir/progress_photos').create(recursive: true);
    } else {
      _baseDir = 'trufit_media';
    }
  }

  // Save a progress photo from raw bytes (works on both web and mobile)
  Future<String> saveProgressPhoto(String date, Uint8List imageBytes, {String poseTag = 'none'}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = kIsWeb
        ? 'web_photo_${date}_$timestamp.jpg'
        : '$_baseDir/progress_photos/${date}_$timestamp.jpg';

    if (!kIsWeb) {
      final file = File(destPath);
      await file.writeAsBytes(imageBytes);
    }

    // Update photo list metadata
    final photos = getProgressPhotos(date);
    photos.add(destPath);
    await _box.put('photos_$date', jsonEncode(photos));

    // Update pose tag metadata
    await _box.put('pose_$destPath', poseTag);

    return destPath;
  }

  // Save a progress photo from a file path (legacy, mobile-only)
  Future<String> saveProgressPhotoFromPath(String date, String sourcePath, {String poseTag = 'none'}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = kIsWeb
        ? sourcePath
        : '$_baseDir/progress_photos/${date}_$timestamp.jpg';

    if (!kIsWeb) {
      await File(sourcePath).copy(destPath);
    }

    final photos = getProgressPhotos(date);
    photos.add(destPath);
    await _box.put('photos_$date', jsonEncode(photos));

    // Update pose tag metadata
    await _box.put('pose_$destPath', poseTag);

    return destPath;
  }

  String getPoseTag(String photoPath) {
    return _box.get('pose_$photoPath') ?? 'none';
  }

  List<String> getProgressPhotos(String date) {
    final jsonStr = _box.get('photos_$date');
    if (jsonStr == null) return [];
    return (jsonDecode(jsonStr) as List).cast<String>();
  }

  List<MapEntry<String, List<String>>> getAllProgressPhotos() {
    final result = <MapEntry<String, List<String>>>[];
    for (final key in _box.keys) {
      final keyStr = key as String;
      if (keyStr.startsWith('photos_')) {
        final date = keyStr.substring(7);
        final photos = getProgressPhotos(date);
        if (photos.isNotEmpty) {
          result.add(MapEntry(date, photos));
        }
      }
    }
    result.sort((a, b) => b.key.compareTo(a.key));
    return result;
  }

  int getAllPhotoCount() {
    int count = 0;
    for (final key in _box.keys) {
      final keyStr = key as String;
      if (keyStr.startsWith('photos_')) {
        final photos = getProgressPhotos(keyStr.substring(7));
        count += photos.length;
      }
    }
    return count;
  }

  Future<void> deletePhoto(String date, String photoPath) async {
    // 1. Remove from photos list
    final photos = getProgressPhotos(date);
    photos.remove(photoPath);
    if (photos.isEmpty) {
      await _box.delete('photos_$date');
    } else {
      await _box.put('photos_$date', jsonEncode(photos));
    }

    // 2. Remove pose tag
    await _box.delete('pose_$photoPath');

    // 3. Delete physical file (if not web)
    if (!kIsWeb) {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> deletePhotos(Map<String, List<String>> photosByDate) async {
    for (final entry in photosByDate.entries) {
      final date = entry.key;
      for (final path in entry.value) {
        await deletePhoto(date, path);
      }
    }
  }
}
