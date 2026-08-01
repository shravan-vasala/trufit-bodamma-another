import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/phase_progress_provider.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/profile_repository.dart';
import 'package:trufit_bodamma/repositories/workout_repository.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import '../helpers/test_hive_setup.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  late ProviderContainer container;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    await setUpTestHive();
    
    final profileRepo = ProfileRepository();
    await profileRepo.init();
    
    final dailyLogRepo = DailyLogRepository();
    await dailyLogRepo.init();

    final workoutRepo = WorkoutRepository();
    await workoutRepo.init();

    final exerciseLogRepo = ExerciseLogRepository();
    await exerciseLogRepo.init();

    container = ProviderContainer(
      overrides: [
        profileRepoProvider.overrideWithValue(profileRepo),
        dailyLogRepoProvider.overrideWithValue(dailyLogRepo),
        workoutRepoProvider.overrideWithValue(workoutRepo),
        exerciseLogRepoProvider.overrideWithValue(exerciseLogRepo),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await tearDownTestHive();
  });

  test('phaseProgressProvider week boundary calculation', () async {
    final profileRepo = container.read(profileRepoProvider);
    final profile = profileRepo.getProfile();
    
    // Set start date to exactly 7 days ago
    final startDate = DateTime.now().subtract(const Duration(days: 7));
    await profileRepo.saveProfile(profile.copyWith(planStartDate: startDate));
    
    // Set current date to today
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    container.read(dateStringProvider.notifier).state = todayStr;
    
    final progress = container.read(phaseProgressProvider);
    
    // Since 7 days have passed, we should be precisely on week 2, day 1
    // daysSinceStart = 7
    // currentWeek = (7 ~/ 7) + 1 = 2
    expect(progress.currentWeek, 2);
    expect(progress.isPhaseActive, true);
  });

  test('phaseProgressProvider week 1 day 7 calculation', () async {
    final profileRepo = container.read(profileRepoProvider);
    final profile = profileRepo.getProfile();
    
    // Set start date to exactly 6 days ago
    final startDate = DateTime.now().subtract(const Duration(days: 6));
    await profileRepo.saveProfile(profile.copyWith(planStartDate: startDate));
    
    // Set current date to today
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    container.read(dateStringProvider.notifier).state = todayStr;
    
    final progress = container.read(phaseProgressProvider);
    
    // Since 6 days have passed, we should be on week 1, day 7
    // daysSinceStart = 6
    // currentWeek = (6 ~/ 7) + 1 = 1
    expect(progress.currentWeek, 1);
    expect(progress.isPhaseActive, true);
  });
}
