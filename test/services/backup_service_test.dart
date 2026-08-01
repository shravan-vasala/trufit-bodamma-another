import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/services/backup_service.dart';
import 'package:hive/hive.dart';
import '../helpers/test_hive_setup.dart';
import 'package:archive/archive.dart';

void main() {
  late BackupService backupService;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock package info
    PackageInfo.setMockInitialValues(
      appName: 'TruFit',
      packageName: 'com.example.trufit',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    
    // Mock shared preferences
    SharedPreferences.setMockInitialValues({});
    
    // Setup Hive
    await setUpTestHive();
    
    tempDir = Directory.systemTemp.createTempSync('backup_test_');

    // Mock path provider method channel
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return tempDir.path;
    });

    backupService = BackupService();
  });

  tearDown(() async {
    await tearDownTestHive();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('createBackup should generate a valid manifest and zip file', () async {
    // Populate some data in one of the boxes BackupService backs up
    final box = await Hive.openBox<String>('habit_config');
    await box.put('test_habit', '{"id":"test_habit"}');

    final backupPath = await backupService.createBackup();
    
    expect(backupPath, isNotNull);
    final file = File(backupPath!);
    expect(file.existsSync(), isTrue);
  });

  test('verifyBackup should read manifest successfully', () async {
    final box = await Hive.openBox<String>('habit_config');
    await box.put('test_habit', '{"id":"test_habit"}');

    final backupPath = await backupService.createBackup();
    final result = await backupService.verifyBackup(backupPath!);
    
    expect(result.isValid, isTrue);
    expect(result.totalEntries, 1);
    expect(result.appVersion, '1.0.0');
    expect(result.schemaVersion, 2);
  });

  test('restoreBackup throws FormatException if schema is too new', () async {
    final archive = Archive();
    final manifestData = utf8.encode(jsonEncode({'schemaVersion': 999}));
    archive.addFile(ArchiveFile('manifest.json', manifestData.length, manifestData));
    final zipData = ZipEncoder().encode(archive);
    final file = File('${tempDir.path}/future_backup.zip');
    await file.writeAsBytes(zipData);

    expect(() => backupService.restoreBackup(file.path), throwsFormatException);
  });

  test('restoreBackup migrates v1 user_profile successfully', () async {
    final archive = Archive();
    final manifestMap = {
      'schemaVersion': 1,
      'boxes': {
        'user_profile': {
          'profile': '{"name": "Old User"}'
        }
      }
    };
    final manifestData = utf8.encode(jsonEncode(manifestMap));
    archive.addFile(ArchiveFile('manifest.json', manifestData.length, manifestData));
    final zipData = ZipEncoder().encode(archive);
    final file = File('${tempDir.path}/v1_backup.zip');
    await file.writeAsBytes(zipData);

    await backupService.restoreBackup(file.path);

    final profileBox = await Hive.openBox<String>('user_profile');
    final profileJson = jsonDecode(profileBox.get('profile')!) as Map<String, dynamic>;
    
    expect(profileJson['name'], 'Old User');
    expect(profileJson['targetProteinG'], 120); // Migrated
    expect(profileJson['targetCarbsG'], 150);   // Migrated
  });

  test('backup round-trip with exercise_prs box', () async {
    // 1. Setup Data
    final box = await Hive.openBox<double>('exercise_prs');
    await box.put('Bench Press', 100.0);
    await box.put('Squat', 150.0);

    // 2. Backup
    final backupPath = await backupService.createBackup();
    expect(backupPath, isNotNull);

    // 3. Clear data
    await box.clear();
    expect(box.isEmpty, isTrue);

    // 4. Restore
    await backupService.restoreBackup(backupPath!);

    // 5. Verify Data restored
    final restoredBox = await Hive.openBox<double>('exercise_prs');
    expect(restoredBox.get('Bench Press'), 100.0);
    expect(restoredBox.get('Squat'), 150.0);
  });

  test('backup includes meal_plans box', () async {
    final mealPlans = await Hive.openBox<String>('meal_plans');
    const customPlan = '{"planName":"Custom Plan","meals":[]}';
    await mealPlans.put('custom_plan', customPlan);

    final backupPath = await backupService.createBackup();
    expect(backupPath, isNotNull);

    await mealPlans.clear();
    expect(mealPlans.isEmpty, isTrue);

    await backupService.restoreBackup(backupPath!);

    final restored = await Hive.openBox<String>('meal_plans');
    expect(restored.get('custom_plan'), customPlan);
  });

  test('encrypted backup create + restore with password', () async {
    final box = await Hive.openBox<String>('habit_config');
    await box.put('test_habit', '{"id":"test_habit"}');

    // Create encrypted backup
    final backupPath = await backupService.createBackup(password: 'my_secure_password');
    expect(backupPath, isNotNull);

    // Verify manifest indicates encryption
    final verifyResult = await backupService.verifyBackup(backupPath!);
    expect(verifyResult.isValid, isTrue);
    expect(verifyResult.isEncrypted, isTrue);

    // Clear data
    await box.clear();
    expect(box.isEmpty, isTrue);

    // Restore encrypted backup with wrong password should fail
    expect(
      () => backupService.restoreBackup(backupPath, password: 'wrong_password'),
      throwsException,
    );

    // Restore encrypted backup with correct password should succeed
    await backupService.restoreBackup(backupPath, password: 'my_secure_password');
    
    final restoredBox = await Hive.openBox<String>('habit_config');
    expect(restoredBox.get('test_habit'), '{"id":"test_habit"}');
  });
}
