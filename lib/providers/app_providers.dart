import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/workout_repository.dart';
import '../repositories/meal_repository.dart';
import '../repositories/daily_log_repository.dart';
import '../repositories/habit_repository.dart';
import '../repositories/body_stats_repository.dart';
import '../repositories/media_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/exercise_log_repository.dart';
import '../services/health_connect_service.dart';
import '../services/backup_service.dart';
import '../models/workout_plan.dart';
import '../models/meal_plan.dart';
import '../models/daily_meal_log.dart';
import '../models/habit.dart';
import '../models/daily_log.dart';
import '../models/body_stats.dart';
import '../models/exercise_log.dart';
import '../models/user_profile.dart';

// ── Date ──

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final dateStringProvider = Provider<String>((ref) {
  final date = ref.watch(selectedDateProvider);
  return DateFormat('yyyy-MM-dd').format(date);
});

final weekOffsetProvider = StateProvider<int>((ref) => 0);

// ── Repositories (singletons) ──

final workoutRepoProvider = Provider<WorkoutRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final mealRepoProvider = Provider<MealRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final dailyLogRepoProvider = Provider<DailyLogRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final habitRepoProvider = Provider<HabitRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final bodyStatsRepoProvider = Provider<BodyStatsRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final mediaRepoProvider = Provider<MediaRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final profileRepoProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final exerciseLogRepoProvider = Provider<ExerciseLogRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final healthConnectServiceProvider = Provider<HealthConnectService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

// Tracks whether the current step value is from HC sync, manual, or nothing
final stepsSourceProvider = StateProvider<StepsSource>((ref) => StepsSource.none);

// ── Workout Providers ──

final workoutPlanProvider = Provider<WorkoutPlan?>((ref) {
  return ref.watch(workoutRepoProvider).getActivePlan();
});

final workoutDayProvider = Provider.family<WorkoutDay?, String>((ref, dayId) {
  return ref.watch(workoutRepoProvider).getWorkoutDay(dayId);
});

// Notifier for exercise completions
class ExerciseCompletionsNotifier extends StateNotifier<Map<String, bool>> {
  final WorkoutRepository _repo;
  final String _date;
  final String _dayId;
  final Ref _ref;

  ExerciseCompletionsNotifier(this._repo, this._date, this._dayId, this._ref)
      : super(_repo.getExerciseCompletions(_date, _dayId));

  void toggle(String exerciseName) {
    _repo.toggleExerciseCompletion(_date, _dayId, exerciseName);
    state = _repo.getExerciseCompletions(_date, _dayId);
    _ref.read(refreshTriggerProvider.notifier).state++;
  }
}

final exerciseCompletionsProvider = StateNotifierProvider.family<
    ExerciseCompletionsNotifier, Map<String, bool>, String>((ref, dayId) {
  final repo = ref.watch(workoutRepoProvider);
  final date = ref.watch(dateStringProvider);
  return ExerciseCompletionsNotifier(repo, date, dayId, ref);
});

// ── Meal Providers ──

final mealPlanProvider = FutureProvider<MealPlan>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/data/seed_meal_plan.json');
  return MealPlan.fromJson(jsonDecode(jsonStr));
});

class DailyMealLogNotifier extends StateNotifier<DailyMealLog> {
  final MealRepository _repo;
  final String _date;
  final Ref _ref;

  DailyMealLogNotifier(this._repo, this._date, this._ref)
      : super(_repo.getDailyLog(_date));

  Future<void> saveMealSlot(String slotName, MealSlotLog slotLog) async {
    await _repo.saveMealSlot(_date, slotName, slotLog);
    state = _repo.getDailyLog(_date);
    _ref.read(refreshTriggerProvider.notifier).state++;
  }

  Future<void> clearMealSlot(String slotName) async {
    await _repo.clearMealSlot(_date, slotName);
    state = _repo.getDailyLog(_date);
    _ref.read(refreshTriggerProvider.notifier).state++;
  }
}

final dailyMealLogProvider =
    StateNotifierProvider<DailyMealLogNotifier, DailyMealLog>((ref) {
  final repo = ref.watch(mealRepoProvider);
  final date = ref.watch(dateStringProvider);
  return DailyMealLogNotifier(repo, date, ref);
});

// ── Daily Log Providers ──

class DailyLogNotifier extends StateNotifier<DailyLog> {
  final DailyLogRepository _repo;
  final Ref _ref;

  DailyLogNotifier(this._repo, String date, this._ref) : super(_repo.getOrCreate(date));

  Future<void> updateWeight(double weight) async {
    await _repo.updateWeight(state.date, weight);
    state = _repo.getOrCreate(state.date);
    _ref.read(refreshTriggerProvider.notifier).state++;
  }

  Future<void> updateSteps(int steps, {String? source}) async {
    await _repo.updateSteps(state.date, steps, source: source ?? 'manual');
    state = _repo.getOrCreate(state.date);
    _ref.read(stepsSourceProvider.notifier).state = 
        (source == 'healthConnect') ? StepsSource.healthConnect : StepsSource.manual;
    _ref.read(refreshTriggerProvider.notifier).state++;
  }

  Future<void> updateSleep(double hours, {String? source}) async {
    await _repo.updateSleep(state.date, hours, source: source ?? 'manual');
    state = _repo.getOrCreate(state.date);

    // Auto-complete sleep habits
    final habitRepo = _ref.read(habitRepoProvider);
    final allHabits = habitRepo.getHabits();
    for (final habit in allHabits.where((h) => h.type == HabitType.autoSleep)) {
      if (hours >= habit.target) {
        await habitRepo.setCompletion(state.date, habit.id, true);
      } else {
        await habitRepo.setCompletion(state.date, habit.id, false);
      }
    }

    _ref.read(refreshTriggerProvider.notifier).state++;
  }

  Future<void> clearSleep() async {
    await _repo.clearSleep(state.date);
    state = _repo.getOrCreate(state.date);
    
    // Un-complete sleep habits if they were completed by this
    final habitRepo = _ref.read(habitRepoProvider);
    final allHabits = habitRepo.getHabits();
    for (final habit in allHabits.where((h) => h.type == HabitType.autoSleep)) {
      await habitRepo.setCompletion(state.date, habit.id, false);
    }
    
    _ref.read(refreshTriggerProvider.notifier).state++;
  }

  Future<void> updateBodyFat(double bodyFat) async {
    await _repo.updateBodyFat(state.date, bodyFat);
    state = _repo.getOrCreate(state.date);
    _ref.read(refreshTriggerProvider.notifier).state++;
  }

  Future<void> markWorkoutCompleted(String dayId) async {
    await _repo.markWorkoutCompleted(state.date, dayId);
    state = _repo.getOrCreate(state.date);
    _ref.read(refreshTriggerProvider.notifier).state++;
  }
}

final dailyLogProvider =
    StateNotifierProvider<DailyLogNotifier, DailyLog>((ref) {
  final repo = ref.watch(dailyLogRepoProvider);
  final date = ref.watch(dateStringProvider);
  ref.watch(refreshTriggerProvider);
  return DailyLogNotifier(repo, date, ref);
});

// ── Habit Providers ──

final habitsProvider = Provider<List<Habit>>((ref) {
  return ref.watch(habitRepoProvider).getHabits();
});

class HabitCompletionsNotifier extends StateNotifier<HabitCompletion> {
  final HabitRepository _repo;
  final String _date;
  final Ref _ref;

  HabitCompletionsNotifier(this._repo, this._date, this._ref)
      : super(_repo.getCompletions(_date));

  Future<void> toggle(String habitId) async {
    await _repo.toggleCheckboxCompletion(_date, habitId);
    state = _repo.getCompletions(_date);
    _ref.read(refreshTriggerProvider.notifier).state++;
  }

  Future<void> updateProgress(String habitId, double progress) async {
    await _repo.updateProgress(_date, habitId, progress);
    state = _repo.getCompletions(_date);
    _ref.read(refreshTriggerProvider.notifier).state++;
  }

  Future<void> setOverride(String habitId, String? overrideValue) async {
    await _repo.setOverride(_date, habitId, overrideValue);
    state = _repo.getCompletions(_date);
    _ref.read(refreshTriggerProvider.notifier).state++;
  }
}

final habitCompletionsProvider =
    StateNotifierProvider<HabitCompletionsNotifier, HabitCompletion>((ref) {
  final repo = ref.watch(habitRepoProvider);
  final date = ref.watch(dateStringProvider);
  ref.watch(refreshTriggerProvider);
  return HabitCompletionsNotifier(repo, date, ref);
});

// ── Body Stats Providers ──

final latestBodyStatsProvider = Provider<BodyStats?>((ref) {
  return ref.watch(bodyStatsRepoProvider).getLatestStats();
});

// ── Profile Providers ──

class ProfileNotifier extends StateNotifier<UserProfile> {
  final ProfileRepository _repo;

  ProfileNotifier(this._repo) : super(_repo.getProfile()) {
    _loadSecureData();
  }

  Future<void> _loadSecureData() async {
    final key = await _repo.getSecureGeminiKey();
    if (key != null && key.isNotEmpty) {
      state = state.copyWith(geminiApiKey: key);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _repo.saveProfile(profile);
    state = profile;
  }

  Future<void> updateGeminiKey(String key) async {
    await _repo.saveSecureGeminiKey(key);
    state = state.copyWith(geminiApiKey: key);
  }

  Future<void> toggleUnit() async {
    await _repo.toggleUnit();
    state = _repo.getProfile();
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfile>((ref) {
  final repo = ref.watch(profileRepoProvider);
  return ProfileNotifier(repo);
});

// ── Exercise Log Providers ──

final exerciseHistoryProvider =
    Provider.family<List<ExerciseLog>, String>((ref, exerciseName) {
  return ref.watch(exerciseLogRepoProvider).getLogsForExercise(exerciseName);
});

// ── Progress Data ──

final dailyLogsRangeProvider =
    Provider.family<List<DailyLog>, (String, String)>((ref, range) {
  final (start, end) = range;
  return ref.watch(dailyLogRepoProvider).getLogsInRange(start, end);
});

final dailyMealLogsRangeProvider =
    Provider.family<List<DailyMealLog>, (String, String)>((ref, range) {
  final (start, end) = range;
  final mealRepo = ref.watch(mealRepoProvider);
  
  // Calculate days difference
  final startDate = DateTime.parse(start);
  final endDate = DateTime.parse(end);
  final daysDiff = endDate.difference(startDate).inDays;
  
  final logs = <DailyMealLog>[];
  for (int i = 0; i <= daysDiff; i++) {
    final d = startDate.add(Duration(days: i));
    final dateStr = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    logs.add(mealRepo.getDailyLog(dateStr));
  }
  return logs;
});

// ── Refresh trigger ──
// Increment this to force providers to rebuild after data changes
final refreshTriggerProvider = StateProvider<int>((ref) => 0);
