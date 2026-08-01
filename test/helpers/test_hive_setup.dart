import 'dart:io';
import 'package:hive/hive.dart';

Future<void> setUpTestHive() async {
  final tempDir = Directory.systemTemp.createTempSync('hive_test_');
  Hive.init(tempDir.path);
}

Future<void> tearDownTestHive() async {
  await Hive.deleteFromDisk();
  await Hive.close();
}
