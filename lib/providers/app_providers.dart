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
import '../repositories/photo_meal_repository.dart';
import '../models/workout_plan.dart';
import '../models/meal_plan.dart';
import '../models/daily_log.dart';
import '../models/habit.dart';
import '../models/body_stats.dart';
import '../models/exercise_log.dart';
import '../models/user_profile.dart';

// ── Date ──

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dateStringProvider = Provider<String>((ref) {
  final date = ref.watch(selectedDateProvider);
  return DateFormat('yyyy-MM-dd').format(date);
});

// ── Repositories (singletons) ──

final workoutRepoProvider = Provider<WorkoutRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final mealRepoProvider = Provider<MealRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final photoMealRepoProvider = Provider<PhotoMealRepository>((ref) {
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

  ExerciseCompletionsNotifier(this._repo, this._date, this._dayId)
      : super(_repo.getExerciseCompletions(_date, _dayId));

  void toggle(String exerciseName) {
    _repo.toggleExerciseCompletion(_date, _dayId, exerciseName);
    state = _repo.getExerciseCompletions(_date, _dayId);
  }
}

final exerciseCompletionsProvider = StateNotifierProvider.family<
    ExerciseCompletionsNotifier, Map<String, bool>, String>((ref, dayId) {
  final repo = ref.watch(workoutRepoProvider);
  final date = ref.watch(dateStringProvider);
  return ExerciseCompletionsNotifier(repo, date, dayId);
});

// ── Meal Providers ──

class MealCompletionsNotifier extends StateNotifier<MealPlan?> {
  final MealRepository _repo;
  final String _date;

  MealCompletionsNotifier(this._repo, this._date)
      : super(_repo.getPlanWithCompletions(_date));

  void toggleMeal(String mealType) {
    _repo.toggleMealCompletion(_date, mealType);
    state = _repo.getPlanWithCompletions(_date);
  }
}

final mealPlanWithCompletionsProvider =
    StateNotifierProvider<MealCompletionsNotifier, MealPlan?>((ref) {
  final repo = ref.watch(mealRepoProvider);
  final date = ref.watch(dateStringProvider);
  return MealCompletionsNotifier(repo, date);
});

// ── Daily Log Providers ──

class DailyLogNotifier extends StateNotifier<DailyLog> {
  final DailyLogRepository _repo;

  DailyLogNotifier(this._repo, String date) : super(_repo.getOrCreate(date));

  Future<void> updateWeight(double weight) async {
    await _repo.updateWeight(state.date, weight);
    state = _repo.getOrCreate(state.date);
  }

  Future<void> updateSteps(int steps) async {
    await _repo.updateSteps(state.date, steps);
    state = _repo.getOrCreate(state.date);
  }

  Future<void> updateSleep(double hours) async {
    await _repo.updateSleep(state.date, hours);
    state = _repo.getOrCreate(state.date);
  }

  Future<void> updateBodyFat(double bodyFat) async {
    await _repo.updateBodyFat(state.date, bodyFat);
    state = _repo.getOrCreate(state.date);
  }

  Future<void> markWorkoutCompleted(String dayId) async {
    await _repo.markWorkoutCompleted(state.date, dayId);
    state = _repo.getOrCreate(state.date);
  }
}

final dailyLogProvider =
    StateNotifierProvider<DailyLogNotifier, DailyLog>((ref) {
  final repo = ref.watch(dailyLogRepoProvider);
  final date = ref.watch(dateStringProvider);
  return DailyLogNotifier(repo, date);
});

// ── Habit Providers ──

final habitsProvider = Provider<List<Habit>>((ref) {
  return ref.watch(habitRepoProvider).getHabits();
});

class HabitCompletionsNotifier extends StateNotifier<HabitCompletion> {
  final HabitRepository _repo;
  final String _date;

  HabitCompletionsNotifier(this._repo, this._date)
      : super(_repo.getCompletions(_date));

  Future<void> toggle(String habitId) async {
    await _repo.toggleCompletion(_date, habitId);
    state = _repo.getCompletions(_date);
  }
}

final habitCompletionsProvider =
    StateNotifierProvider<HabitCompletionsNotifier, HabitCompletion>((ref) {
  final repo = ref.watch(habitRepoProvider);
  final date = ref.watch(dateStringProvider);
  return HabitCompletionsNotifier(repo, date);
});

// ── Body Stats Providers ──

final latestBodyStatsProvider = Provider<BodyStats?>((ref) {
  return ref.watch(bodyStatsRepoProvider).getLatestStats();
});

// ── Profile Providers ──

class ProfileNotifier extends StateNotifier<UserProfile> {
  final ProfileRepository _repo;

  ProfileNotifier(this._repo) : super(_repo.getProfile());

  Future<void> updateProfile(UserProfile profile) async {
    await _repo.saveProfile(profile);
    state = profile;
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

// ── Refresh trigger ──
// Increment this to force providers to rebuild after data changes
final refreshTriggerProvider = StateProvider<int>((ref) => 0);
