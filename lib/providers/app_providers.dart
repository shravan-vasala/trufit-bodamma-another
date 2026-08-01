import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/coach_note_repository.dart';
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
import '../services/coach_service.dart';
import '../services/csv_export_service.dart';
import '../models/workout_plan.dart';
import '../models/meal_plan.dart';
import '../models/daily_meal_log.dart';
import '../models/habit.dart';
import '../models/daily_log.dart';
import '../models/body_stats.dart';
import '../models/exercise_log.dart';
import '../models/user_profile.dart';
export 'rest_timer_provider.dart';
export 'phase_progress_provider.dart';
export 'theme_provider.dart';
export 'daily_score_provider.dart';

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

final coachNoteRepoProvider = Provider<CoachNoteRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final healthConnectServiceProvider = Provider<HealthConnectService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  return CsvExportService();
});

final coachServiceProvider = Provider<CoachService>((ref) {
  final profile = ref.watch(profileProvider);
  return CoachService(apiKey: profile.geminiApiKey);
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

// Provider to trigger rebuilds when an exercise log is added/updated
final exerciseLogsUpdateProvider = StateProvider<int>((ref) => 0);


// ── Meal Providers ──

final mealPlanProvider = Provider<MealPlan?>((ref) {
  final repo = ref.watch(mealRepoProvider);
  final profile = ref.watch(profileProvider);
  
  final activePlanId = profile.activeMealPlan ?? 'standard_plan';
  return repo.getMealPlan(activePlanId);
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
  }

  Future<void> clearMealSlot(String slotName) async {
    await _repo.clearMealSlot(_date, slotName);
    state = _repo.getDailyLog(_date);
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
  }

  Future<void> updateSteps(int steps, {String? source}) async {
    await _repo.updateSteps(state.date, steps, source: source ?? 'manual');
    state = _repo.getOrCreate(state.date);
    _ref.read(stepsSourceProvider.notifier).state = 
        (source == 'healthConnect') ? StepsSource.healthConnect : StepsSource.manual;
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
    _ref.invalidate(habitCompletionsProvider);
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
    _ref.invalidate(habitCompletionsProvider);
  }

  Future<void> updateBodyFat(double bodyFat) async {
    await _repo.updateBodyFat(state.date, bodyFat);
    state = _repo.getOrCreate(state.date);
  }

  Future<void> markWorkoutCompleted(String dayId) async {
    await _repo.markWorkoutCompleted(state.date, dayId);
    state = _repo.getOrCreate(state.date);

    // Auto-start phase if not started
    final profile = _ref.read(profileProvider);
    if (profile.planStartDate == null) {
      final now = DateTime.now();
      _ref.read(profileProvider.notifier).updateProfile(profile.copyWith(
        planStartDate: DateTime(now.year, now.month, now.day),
        currentPhaseWeek: 1,
      ));
    }
  }
}

final dailyLogProvider =
    StateNotifierProvider<DailyLogNotifier, DailyLog>((ref) {
  final repo = ref.watch(dailyLogRepoProvider);
  final date = ref.watch(dateStringProvider);
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
  }

  Future<void> updateProgress(String habitId, double progress) async {
    await _repo.updateProgress(_date, habitId, progress);
    state = _repo.getCompletions(_date);
  }

  Future<void> setOverride(String habitId, String? overrideValue) async {
    await _repo.setOverride(_date, habitId, overrideValue);
    state = _repo.getCompletions(_date);
  }
}

final habitCompletionsProvider =
    StateNotifierProvider<HabitCompletionsNotifier, HabitCompletion>((ref) {
  final repo = ref.watch(habitRepoProvider);
  final date = ref.watch(dateStringProvider);
  return HabitCompletionsNotifier(repo, date, ref);
});

final habitStreakProvider = Provider.family<int, String>((ref, habitId) {
  final habits = ref.watch(habitsProvider);
  final habit = habits.firstWhere((h) => h.id == habitId, orElse: () => Habit(id: '', name: '', icon: '', target: 1));
  if (habit.id.isEmpty) return 0;
  
  final dateStr = ref.watch(dateStringProvider);
  
  // Reactive to today's changes
  ref.watch(habitCompletionsProvider);
  ref.watch(dailyLogProvider);
  
  final habitRepo = ref.watch(habitRepoProvider);
  final dailyLogRepo = ref.watch(dailyLogRepoProvider);
  
  int streak = 0;
  DateTime current = DateTime.parse(dateStr);
  
  // Check today
  final todayCompletions = habitRepo.getCompletions(dateStr);
  final todayLog = dailyLogRepo.getLog(dateStr) ?? DailyLog(date: dateStr);
  if (isHabitCompleted(habit, todayCompletions, todayLog)) {
    streak++;
  }
  
  // Go backward
  DateTime checkDate = current.subtract(Duration(days: 1));
  while (streak < 365) {
    final dStr = '${checkDate.year.toString().padLeft(4, '0')}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
    final comp = habitRepo.getCompletions(dStr);
    final log = dailyLogRepo.getLog(dStr) ?? DailyLog(date: dStr);
    
    if (isHabitCompleted(habit, comp, log)) {
      streak++;
      checkDate = checkDate.subtract(Duration(days: 1));
    } else {
      break;
    }
  }
  return streak;
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

// ── Refresh trigger removed ──
// Explicit ref.invalidate() is now used.

// ── Coach Notes ──
class CoachNoteNotifier extends StateNotifier<AsyncValue<CoachNote>> {
  final Ref _ref;

  CoachNoteNotifier(this._ref) : super(AsyncValue.loading()) {
    // Auto-fetch on first build if no cache exists
    final dateStr = _ref.read(dateStringProvider);
    final repo = _ref.read(coachNoteRepoProvider);
    final cached = repo.getNote(dateStr);
    if (cached != null) {
      state = AsyncValue.data(cached);
    } else {
      fetchNote();
    }
  }

  Future<void> fetchNote({bool force = false}) async {
    final dateStr = _ref.read(dateStringProvider);
    final repo = _ref.read(coachNoteRepoProvider);
    
    if (!force) {
      final cached = repo.getNote(dateStr);
      if (cached != null) {
        if (mounted) state = AsyncValue.data(cached);
        return;
      }
    }
    
    state = AsyncValue.loading();
    try {
      final coachService = _ref.read(coachServiceProvider);
      final profile = _ref.read(profileProvider);
      final dailyLog = _ref.read(dailyLogProvider);
      final dailyLogRepo = _ref.read(dailyLogRepoProvider);
      final habitRepo = _ref.read(habitRepoProvider);
      
      // Calculate today's habits
      final habits = _ref.read(habitsProvider);
      final completions = _ref.read(habitCompletionsProvider);
      int habitsDone = 0;
      for (final h in habits) {
        if (isHabitCompleted(h, completions, dailyLog)) habitsDone++;
      }

      // Calculate yesterday's habits
      final yesterday = DateTime.parse(dateStr).subtract(Duration(days: 1));
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
      final yCompletions = habitRepo.getCompletions(yesterdayStr);
      final yLog = dailyLogRepo.getLog(yesterdayStr) ?? DailyLog(date: yesterdayStr);
      int yHabitsDone = 0;
      for (final h in habits) {
        if (isHabitCompleted(h, yCompletions, yLog)) yHabitsDone++;
      }
      final yesterdayHabitRate = habits.isEmpty ? 0.0 : yHabitsDone / habits.length;

      // Calculate weight trend (7 days)
      String weightTrend = 'stable';
      final todayWeight = dailyLog.weight ?? profile.targetWeight ?? 0.0;
      final weekAgo = DateTime.parse(dateStr).subtract(Duration(days: 7));
      final weekAgoStr = DateFormat('yyyy-MM-dd').format(weekAgo);
      final weekAgoLog = dailyLogRepo.getLog(weekAgoStr);
      final pastWeight = weekAgoLog?.weight ?? profile.targetWeight ?? 0.0;
      if (todayWeight > pastWeight + 0.5) {
        weightTrend = 'up';
      } else if (todayWeight < pastWeight - 0.5) {
        weightTrend = 'down';
      }

      // Calculate workouts
      final workoutPlan = _ref.read(workoutPlanProvider);
      int workoutsTotal = 0;
      int workoutsDone = 0;
      bool isRestDay = false;
      int daysSinceLastWorkout = 0;

      if (workoutPlan != null && workoutPlan.days.isNotEmpty) {
        final weekday = DateTime.parse(dateStr).weekday;
        final isSunday = weekday == DateTime.sunday;
        final dayIndex = isSunday ? 0 : (weekday - 1).clamp(0, workoutPlan.days.length - 1);
        final dayIdTarget = isSunday ? 'Rest' : workoutPlan.days[dayIndex].dayId;
        final day = workoutPlan.days.firstWhere((d) => d.dayId == dayIdTarget, orElse: () => workoutPlan.days[dayIndex]);
        
        isRestDay = (isSunday || day.sections.isEmpty);
        workoutsTotal = isRestDay ? 1 : day.sections.length;
        
        if (isRestDay) {
          if (dailyLog.workoutCompleted) workoutsDone = 1;
          
          // Calculate days since last workout
          DateTime checkDate = yesterday;
          while (daysSinceLastWorkout < 14) {
            final checkStr = DateFormat('yyyy-MM-dd').format(checkDate);
            final cLog = dailyLogRepo.getLog(checkStr);
            if (cLog != null && cLog.workoutCompleted) break;
            daysSinceLastWorkout++;
            checkDate = checkDate.subtract(Duration(days: 1));
          }
        } else {
          final logRepo = _ref.read(exerciseLogRepoProvider);
          for (final sec in day.sections) {
            if (sec.exercises.isNotEmpty && sec.exercises.every((ex) => logRepo.hasLog(dateStr, ex.name))) {
              workoutsDone++;
            }
          }
        }
      } else {
        isRestDay = true;
      }
      
      // Calculate calories
      final mealLog = _ref.read(dailyMealLogProvider);

      final noteStr = await coachService.generateNote(
        userName: profile.name,
        steps: dailyLog.steps ?? 0,
        sleep: dailyLog.sleepHours ?? 0.0,
        habitsDone: habitsDone,
        habitsTotal: habits.length,
        calories: mealLog.totalCalories,
        workoutsDone: workoutsDone,
        workoutsTotal: workoutsTotal,
        yesterdayHabitRate: yesterdayHabitRate,
        weightTrend: weightTrend,
        isRestDay: isRestDay,
        daysSinceLastWorkout: daysSinceLastWorkout,
      ).timeout(Duration(seconds: 15));
      
      final isAi = coachService.apiKey != null && coachService.apiKey!.isNotEmpty;
      final newNote = CoachNote(date: dateStr, note: noteStr, isAi: isAi);
      await repo.saveNote(newNote);

      if (mounted) {
        state = AsyncValue.data(newNote);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final coachNoteProvider = StateNotifierProvider<CoachNoteNotifier, AsyncValue<CoachNote>>((ref) {
  return CoachNoteNotifier(ref);
});

