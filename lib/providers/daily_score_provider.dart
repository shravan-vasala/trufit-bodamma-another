import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import '../models/habit.dart';

class DailyScore {
  final int totalScore;
  final bool isFutureDate;
  final double habitsScore;
  final double habitsMax;
  final double workoutsScore;
  final double workoutsMax;
  final double mealsScore;
  final double mealsMax;
  final double stepsScore;
  final double stepsMax;

  DailyScore({
    required this.totalScore,
    required this.isFutureDate,
    required this.habitsScore,
    required this.habitsMax,
    required this.workoutsScore,
    required this.workoutsMax,
    required this.mealsScore,
    required this.mealsMax,
    required this.stepsScore,
    required this.stepsMax,
  });
}

final dailyScoreProvider = Provider<DailyScore>((ref) {
  final dateStr = ref.watch(dateStringProvider);
  final date = DateTime.parse(dateStr);
  final today = DateTime.now();
  final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));

  if (isFuture) {
    return DailyScore(
      totalScore: 0,
      isFutureDate: true,
      habitsScore: 0,
      habitsMax: 0,
      workoutsScore: 0,
      workoutsMax: 0,
      mealsScore: 0,
      mealsMax: 0,
      stepsScore: 0,
      stepsMax: 0,
    );
  }

  // 1. Habits (Max 40)
  final habits = ref.watch(habitsProvider);
  final habitCompletions = ref.watch(habitCompletionsProvider);
  final dailyLog = ref.watch(dailyLogProvider);
  
  double habitsScore = 0;
  double habitsMax = 40;
  bool hasStepsHabit = false;
  double stepsTarget = 10000;

  if (habits.isNotEmpty) {
    int habitsDone = 0;
    for (final h in habits) {
      if (h.name.toLowerCase().contains('steps') || h.name.toLowerCase().contains('walk')) {
        hasStepsHabit = true;
        stepsTarget = h.target.toDouble();
      }
      if (isHabitCompleted(h, habitCompletions, dailyLog)) {
        habitsDone++;
      }
    }
    habitsScore = (habitsDone / habits.length) * habitsMax;
  }

  // 2. Workouts (Max 30)
  double workoutsScore = 0;
  double workoutsMax = 30;
  final workoutPlan = ref.watch(workoutPlanProvider);
  
  if (workoutPlan != null && workoutPlan.days.isNotEmpty) {
    final weekday = date.weekday;
    final isSunday = weekday == DateTime.sunday;
    final dayIndex = isSunday ? 0 : (weekday - 1).clamp(0, workoutPlan.days.length - 1);
    final dayIdTarget = isSunday ? 'Rest' : workoutPlan.days[dayIndex].dayId;
    final day = workoutPlan.days.firstWhere((d) => d.dayId == dayIdTarget, orElse: () => workoutPlan.days[dayIndex]);
    
    final isRestDay = (isSunday || day.sections.isEmpty);
    
    if (isRestDay) {
      if (dailyLog.workoutCompleted) workoutsScore = workoutsMax;
    } else {
      final logRepo = ref.watch(exerciseLogRepoProvider);
      
      int workoutsDone = 0;
      int workoutsTotal = day.sections.length;
      
      if (workoutsTotal > 0) {
        for (final sec in day.sections) {
          if (sec.exercises.isNotEmpty && sec.exercises.every((ex) => logRepo.hasLog(dateStr, ex.name))) {
            workoutsDone++;
          }
        }
        workoutsScore = (workoutsDone / workoutsTotal) * workoutsMax;
      }
    }
  } else {
    // No plan, just rely on the manual workout completed button
    if (dailyLog.workoutCompleted) workoutsScore = workoutsMax;
  }

  // 3. Meals (Max 20)
  double mealsScore = 0;
  double mealsMax = 20;
  final mealPlan = ref.watch(mealPlanProvider);
  final mealLog = ref.watch(dailyMealLogProvider);
  
  if (mealPlan != null && mealPlan.meals.isNotEmpty) {
    int slotsLogged = 0;
    int slotsTotal = mealPlan.meals.length;
    
    for (final slot in mealPlan.meals) {
      if (mealLog.customSlots.containsKey(slot.type)) {
        slotsLogged++;
      }
    }
    mealsScore = (slotsLogged / slotsTotal) * mealsMax;
  }

  // 4. Steps (Max 10) - only if steps habit exists
  double stepsScore = 0;
  double stepsMax = hasStepsHabit ? 10 : 0;
  
  if (hasStepsHabit && stepsTarget > 0) {
    final actualSteps = dailyLog.steps ?? 0;
    final fraction = (actualSteps / stepsTarget).clamp(0.0, 1.0);
    stepsScore = fraction * stepsMax;
  }

  // Calculate final score
  final totalEarned = habitsScore + workoutsScore + mealsScore + stepsScore;
  final totalPossible = habitsMax + workoutsMax + mealsMax + stepsMax;
  
  int finalScore = 0;
  if (totalPossible > 0) {
    finalScore = ((totalEarned / totalPossible) * 100).round();
  }

  return DailyScore(
    totalScore: finalScore,
    isFutureDate: false,
    habitsScore: habitsScore,
    habitsMax: habitsMax,
    workoutsScore: workoutsScore,
    workoutsMax: workoutsMax,
    mealsScore: mealsScore,
    mealsMax: mealsMax,
    stepsScore: stepsScore,
    stepsMax: stepsMax,
  );
});
