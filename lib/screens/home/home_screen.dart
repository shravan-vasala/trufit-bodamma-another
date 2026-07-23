import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import 'widgets/week_calendar_strip.dart';
import 'widgets/meals_card.dart';
import 'widgets/habits_card.dart';
import 'widgets/daily_progress_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final plan = ref.watch(workoutPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Top header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hey Mamatha! 💪',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, dd MMM yyyy').format(selectedDate),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Week Calendar Strip
              const WeekCalendarStrip(),
              
              if (selectedDate.year != DateTime.now().year ||
                  selectedDate.month != DateTime.now().month ||
                  selectedDate.day != DateTime.now().day)
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Viewing ${DateFormat('EEE, dd MMM').format(selectedDate)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(selectedDateProvider.notifier).state = DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                            );
                            ref.read(weekOffsetProvider.notifier).state = 0;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
              const SizedBox(height: 20),

              // Today's Workout CTA
              if (plan != null && plan.days.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _WorkoutCta(plan: plan),
                ),
              const SizedBox(height: 12),

              // Meals Card
              const MealsCard(),
              const SizedBox(height: 4),

              // Habits Card
              const HabitsCard(),
              const SizedBox(height: 4),

              // Daily Progress Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'DAILY PROGRESS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              const DailyProgressGrid(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutCta extends ConsumerWidget {
  const _WorkoutCta({required this.plan});

  final dynamic plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutPlan = ref.watch(workoutPlanProvider);
    if (workoutPlan == null || workoutPlan.days.isEmpty) return const SizedBox();

    final dateStr = ref.watch(dateStringProvider);
    final dailyLog = ref.watch(dailyLogProvider);
    final weekday = DateTime.parse(dateStr).weekday;

    // Sunday is Rest Day
    if (weekday == DateTime.sunday) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.lavender,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rest Day 🧘‍♀️',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Time to recover and relax!',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final dayIndex = (weekday - 1).clamp(0, workoutPlan.days.length - 1);
    final day = workoutPlan.days[dayIndex];
    final isCompleted = dailyLog.workoutCompleted;
    
    final selectedDate = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = selectedDate.isAfter(today);

    if (day.sections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.lavenderCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rest Day',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Take a break and recover',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: isFuture
          ? null
          : () {
              context.go('/home/workout/${day.dayId}');
            },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isFuture ? AppColors.white : null,
          gradient: isFuture
              ? null
              : (isCompleted
                  ? const LinearGradient(colors: [AppColors.green, Color(0xFF16A34A)])
                  : AppColors.primaryGradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isFuture
                  ? AppColors.textLight.withValues(alpha: 0.1)
                  : (isCompleted ? AppColors.green : AppColors.primary)
                      .withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isFuture
                    ? AppColors.textLight.withValues(alpha: 0.1)
                    : AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isFuture
                    ? Icons.lock_outline_rounded
                    : (isCompleted ? Icons.check_circle_rounded : Icons.fitness_center_rounded),
                color: isFuture ? AppColors.textLight : AppColors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFuture
                        ? 'Upcoming Workout'
                        : (isCompleted ? 'Workout Complete! 🎉' : 'Today\'s Workout'),
                    style: TextStyle(
                      color: isFuture ? AppColors.textMedium : AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.label ?? day.dayId,
                    style: TextStyle(
                      color: isFuture
                          ? AppColors.textLight
                          : AppColors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isFuture)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.white.withValues(alpha: 0.7),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
