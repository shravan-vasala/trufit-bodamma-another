import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class MediaRepository {
  static const String _boxName = 'media_metadata';

  late Box<String> _box;
  late String _baseDir;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = '${appDir.path}/trufit_media';
    await Directory(_baseDir).create(recursive: true);
    await Directory('$_baseDir/progress_photos').create(recursive: true);
    await Directory('$_baseDir/form_check_videos').create(recursive: true);
  }

  // Progress photos
  Future<String> saveProgressPhoto(String date, String sourcePath) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = sourcePath.split('.').last;
    final destPath = '$_baseDir/progress_photos/${date}_$timestamp.$ext';
    await File(sourcePath).copy(destPath);

    // Update metadata
    final photos = getProgressPhotos(date);
    photos.add(destPath);
    await _box.put('photos_$date', jsonEncode(photos));

    return destPath;
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

  // Form check videos
  Future<String> saveFormCheckVideo(
      String date, String exerciseName, String sourcePath) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = sourcePath.split('.').last;
    final safeName = exerciseName.replaceAll(RegExp(r'[^\w]'), '_');
    final destPath = '$_baseDir/form_check_videos/${date}_${safeName}_$timestamp.$ext';
    await File(sourcePath).copy(destPath);

    final key = 'video_${date}_$safeName';
    final videos = getFormCheckVideos(date, exerciseName);
    videos.add(destPath);
    await _box.put(key, jsonEncode(videos));

    return destPath;
  }

  List<String> getFormCheckVideos(String date, String exerciseName) {
    final safeName = exerciseName.replaceAll(RegExp(r'[^\w]'), '_');
    final key = 'video_${date}_$safeName';
    final jsonStr = _box.get(key);
    if (jsonStr == null) return [];
    return (jsonDecode(jsonStr) as List).cast<String>();
  }
}
