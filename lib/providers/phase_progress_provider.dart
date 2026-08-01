import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'app_providers.dart';

class PhaseProgress {
  final int currentWeek;
  final int totalWeeks;
  final int completedDaysThisWeek;
  final int requiredDaysPerWeek;
  final bool isPhaseActive;

  PhaseProgress({
    required this.currentWeek,
    required this.totalWeeks,
    required this.completedDaysThisWeek,
    required this.requiredDaysPerWeek,
    required this.isPhaseActive,
  });

  bool get isWeekComplete => completedDaysThisWeek >= requiredDaysPerWeek;
  bool get isPhaseComplete => currentWeek > totalWeeks;
}

final phaseProgressProvider = Provider<PhaseProgress>((ref) {
  final profile = ref.watch(profileProvider);
  final dateStr = ref.watch(dateStringProvider);
  final dailyLogRepo = ref.watch(dailyLogRepoProvider);
  
  // Rebuild if logs change
  ref.watch(dailyLogProvider);

  final int totalWeeks = 8;
  final int requiredDaysPerWeek = 4;

  if (profile.planStartDate == null) {
    return PhaseProgress(
      currentWeek: 1,
      totalWeeks: totalWeeks,
      completedDaysThisWeek: 0,
      requiredDaysPerWeek: requiredDaysPerWeek,
      isPhaseActive: false,
    );
  }

  final today = DateTime.parse(dateStr);
  
  // Strip time from start date just in case
  final startDate = DateTime(
    profile.planStartDate!.year, 
    profile.planStartDate!.month, 
    profile.planStartDate!.day
  );

  final daysSinceStart = today.difference(startDate).inDays;
  
  // If today is before start date (shouldn't happen, but just in case)
  if (daysSinceStart < 0) {
    return PhaseProgress(
      currentWeek: 1,
      totalWeeks: totalWeeks,
      completedDaysThisWeek: 0,
      requiredDaysPerWeek: requiredDaysPerWeek,
      isPhaseActive: true,
    );
  }

  final currentWeek = (daysSinceStart ~/ 7) + 1;
  final weekStartDate = startDate.add(Duration(days: (currentWeek - 1) * 7));

  final workoutPlan = ref.watch(workoutPlanProvider);
  final exerciseLogRepo = ref.watch(exerciseLogRepoProvider);
  ref.watch(exerciseLogsUpdateProvider); // rebuild on log changes

  int completedDaysThisWeek = 0;
  for (int i = 0; i < 7; i++) {
    final checkDate = weekStartDate.add(Duration(days: i));
    if (checkDate.isAfter(today)) break; // Don't check future days

    final checkStr = DateFormat('yyyy-MM-dd').format(checkDate);
    final log = dailyLogRepo.getLog(checkStr);
    
    if (workoutPlan != null && workoutPlan.days.isNotEmpty) {
      final weekday = checkDate.weekday;
      final isSunday = weekday == DateTime.sunday;
      final dayIndex = isSunday ? 0 : (weekday - 1).clamp(0, workoutPlan.days.length - 1);
      final dayIdTarget = isSunday ? 'Rest' : workoutPlan.days[dayIndex].dayId;
      final day = workoutPlan.days.firstWhere((d) => d.dayId == dayIdTarget, orElse: () => workoutPlan.days[dayIndex]);
      
      final isRestDay = (isSunday || day.sections.isEmpty);
      
      if (isRestDay) {
        if (log != null && log.workoutCompleted) completedDaysThisWeek++;
      } else {
        int workoutsDone = 0;
        int workoutsTotal = day.sections.length;
        
        if (workoutsTotal > 0) {
          for (final sec in day.sections) {
            if (sec.exercises.isNotEmpty && sec.exercises.every((ex) => exerciseLogRepo.hasLog(checkStr, ex.name))) {
              workoutsDone++;
            }
          }
          if (workoutsDone == workoutsTotal) completedDaysThisWeek++;
        }
      }
    } else {
      if (log != null && log.workoutCompleted) {
        completedDaysThisWeek++;
      }
    }
  }

  return PhaseProgress(
    currentWeek: currentWeek,
    totalWeeks: totalWeeks,
    completedDaysThisWeek: completedDaysThisWeek,
    requiredDaysPerWeek: requiredDaysPerWeek,
    isPhaseActive: true,
  );
});
