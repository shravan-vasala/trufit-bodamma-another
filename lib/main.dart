import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'repositories/workout_repository.dart';
import 'repositories/meal_repository.dart';
import 'repositories/daily_log_repository.dart';
import 'repositories/habit_repository.dart';
import 'repositories/body_stats_repository.dart';
import 'repositories/media_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/exercise_log_repository.dart';
import 'services/health_connect_service.dart';
import 'providers/app_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize all repositories
  final workoutRepo = WorkoutRepository();
  final mealRepo = MealRepository();
  final dailyLogRepo = DailyLogRepository();
  final habitRepo = HabitRepository();
  final bodyStatsRepo = BodyStatsRepository();
  final mediaRepo = MediaRepository();
  final profileRepo = ProfileRepository();
  final exerciseLogRepo = ExerciseLogRepository();
  final healthConnectService = HealthConnectService();

  await Future.wait([
    workoutRepo.init(),
    mealRepo.init(),
    dailyLogRepo.init(),
    habitRepo.init(),
    bodyStatsRepo.init(),
    mediaRepo.init(),
    profileRepo.init(),
    exerciseLogRepo.init(),
    healthConnectService.init(),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        workoutRepoProvider.overrideWithValue(workoutRepo),
        mealRepoProvider.overrideWithValue(mealRepo),
        dailyLogRepoProvider.overrideWithValue(dailyLogRepo),
        habitRepoProvider.overrideWithValue(habitRepo),
        bodyStatsRepoProvider.overrideWithValue(bodyStatsRepo),
        mediaRepoProvider.overrideWithValue(mediaRepo),
        profileRepoProvider.overrideWithValue(profileRepo),
        exerciseLogRepoProvider.overrideWithValue(exerciseLogRepo),
        healthConnectServiceProvider.overrideWithValue(healthConnectService),
      ],
      child: const TruFitApp(),
    ),
  );
}

class TruFitApp extends StatelessWidget {
  const TruFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TruFit Bodamma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
