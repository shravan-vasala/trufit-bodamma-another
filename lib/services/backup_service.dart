import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class BackupVerificationResult {
  final bool isValid;
  final int totalEntries;
  final int photoCount;
  final String? errorMessage;

  BackupVerificationResult({
    required this.isValid,
    required this.totalEntries,
    required this.photoCount,
    this.errorMessage,
  });
}

class BackupService {
  /// The list of known Hive boxes to back up.
  static const List<String> _boxesToBackup = [
    'health_connect_meta',
    'workout_plans',
    'workout_sessions',
    'user_profile',
    'scanned_photo_meals',
    'media_metadata',
    'daily_meal_logs',
    'meal_completions',
    'habit_config',
    'habit_completions',
    'exercise_logs',
    'daily_logs',
    'body_stats',
  ];

  /// Creates a ZIP archive containing a manifest of all Hive data and the physical photos.
  Future<String?> createBackup() async {
    try {
      final manifest = <String, Map<String, dynamic>>{};

      // 1. Read all Hive boxes into the manifest
      for (final boxName in _boxesToBackup) {
        final box = await Hive.openBox<String>(boxName);
        final boxData = <String, dynamic>{};
        for (final key in box.keys) {
          boxData[key.toString()] = box.get(key);
        }
        manifest[boxName] = boxData;
      }

      // 2. Identify all photos to backup
      final photosToBackup = <String>{};
      if (manifest.containsKey('media_metadata')) {
        final mediaBox = manifest['media_metadata']!;
        for (final key in mediaBox.keys) {
          if (key.startsWith('photos_')) {
            final String jsonStr = mediaBox[key];
            try {
              final List<dynamic> paths = jsonDecode(jsonStr);
              for (final path in paths) {
                photosToBackup.add(path.toString());
              }
            } catch (_) {}
          }
        }
      }

      // 3. Create the Archive
      final archive = Archive();
      
      // Add manifest.json
      final manifestBytes = utf8.encode(jsonEncode(manifest));
      archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

      // Add photos
      for (final photoPath in photosToBackup) {
        final file = File(photoPath);
        if (await file.exists()) {
          final fileName = file.uri.pathSegments.last;
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile('photos/$fileName', bytes.length, bytes));
        }
      }

      // 4. Save to a temporary zip file
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final zipFile = File('${tempDir.path}/trufit_backup_$timestamp.zip');
      await zipFile.writeAsBytes(zipBytes);

      return zipFile.path;
    } catch (e) {
      debugPrint('Backup error: $e');
      return null;
    }
  }

  /// Extracts the backup to a temporary directory and verifies its contents.
  Future<BackupVerificationResult> verifyBackup(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        return BackupVerificationResult(isValid: false, totalEntries: 0, photoCount: 0, errorMessage: 'File does not exist');
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find manifest
      final manifestFile = archive.findFile('manifest.json');
      if (manifestFile == null) {
        return BackupVerificationResult(isValid: false, totalEntries: 0, photoCount: 0, errorMessage: 'Missing manifest.json');
      }

      final manifestContent = utf8.decode(manifestFile.content as List<int>);
      final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

      int entriesCount = 0;
      for (final box in manifest.values) {
        entriesCount += (box as Map).length;
      }

      // Count photos in archive
      int photosCount = archive.where((f) => f.name.startsWith('photos/') && f.isFile).length;

      return BackupVerificationResult(
        isValid: true,
        totalEntries: entriesCount,
        photoCount: photosCount,
      );
    } catch (e) {
      return BackupVerificationResult(isValid: false, totalEntries: 0, photoCount: 0, errorMessage: e.toString());
    }
  }

  /// Restores a backup. WARNING: This will overwrite existing data.
  Future<bool> restoreBackup(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final manifestFile = archive.findFile('manifest.json');
      if (manifestFile == null) return false;

      final manifestContent = utf8.decode(manifestFile.content as List<int>);
      final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

      // 1. Overwrite all Hive boxes
      for (final boxName in manifest.keys) {
        final box = await Hive.openBox<String>(boxName);
        await box.clear(); // Wipe current data
        final Map<String, dynamic> boxData = manifest[boxName];
        for (final entry in boxData.entries) {
          await box.put(entry.key, entry.value.toString());
        }
      }

      // 2. Restore photos
      // To correctly map paths, we must place them exactly where they were, or update the manifest.
      // Since photos are saved to the app's documents directory, we can recreate them there.
      final docDir = await getApplicationDocumentsDirectory();
      for (final file in archive) {
        if (file.isFile && file.name.startsWith('photos/')) {
          // Photo files are handled below for path mapping.
        }
      }
      
      // Wait, we need to map old paths to new paths if the device changed.
      // Let's do that!
      final oldPathMap = <String, String>{};
      for (final file in archive) {
        if (file.isFile && file.name.startsWith('photos/')) {
          final fileName = file.name.split('/').last;
          final newFilePath = '${docDir.path}/$fileName';
          final newFile = File(newFilePath);
          await newFile.writeAsBytes(file.content as List<int>);
          oldPathMap[fileName] = newFilePath;
        }
      }

      // Fix paths in media_metadata
      if (manifest.containsKey('media_metadata')) {
        final mediaBox = await Hive.openBox<String>('media_metadata');
        final currentKeys = mediaBox.keys.toList();
        for (final key in currentKeys) {
          if (key.toString().startsWith('photos_')) {
            final jsonStr = mediaBox.get(key);
            if (jsonStr != null) {
              final List<dynamic> oldPaths = jsonDecode(jsonStr);
              final List<String> newPaths = [];
              for (final oldPath in oldPaths) {
                final fileName = File(oldPath.toString()).uri.pathSegments.last;
                if (oldPathMap.containsKey(fileName)) {
                  newPaths.add(oldPathMap[fileName]!);
                  
                  // Also we need to fix the pose tag keys
                  final oldPoseKey = 'pose_$oldPath';
                  final poseVal = mediaBox.get(oldPoseKey);
                  if (poseVal != null) {
                    await mediaBox.put('pose_${oldPathMap[fileName]}', poseVal);
                    await mediaBox.delete(oldPoseKey);
                  }
                } else {
                  // Fallback: keep the old path if it wasn't backed up (edge case)
                  newPaths.add(oldPath.toString());
                }
              }
              await mediaBox.put(key, jsonEncode(newPaths));
            }
          }
        }
      }

      // Also fix paths in scanned_photo_meals
      if (manifest.containsKey('scanned_photo_meals')) {
        final mealBox = await Hive.openBox<String>('scanned_photo_meals');
        final keys = mealBox.keys.toList();
        for (final key in keys) {
          final oldPath = key.toString();
          final fileName = File(oldPath).uri.pathSegments.last;
          if (oldPathMap.containsKey(fileName)) {
            final val = mealBox.get(oldPath);
            await mealBox.put(oldPathMap[fileName]!, val!);
            await mealBox.delete(oldPath);
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }
}
