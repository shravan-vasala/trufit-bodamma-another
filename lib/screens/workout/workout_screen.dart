import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/workout_plan.dart';
import 'widgets/exercise_card.dart';
import 'widgets/rest_timer_label.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key, required this.dayId});

  final String dayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(workoutPlanProvider);
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('No workout plan found')),
      );
    }

    WorkoutDay? day;
    for (final d in plan.days) {
      if (d.dayId == dayId) {
        day = d;
        break;
      }
    }

    if (day == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('Workout day not found')),
      );
    }

    final workoutDay = day;

    final completions = ref.watch(exerciseCompletionsProvider(dayId));
    final totalExercises = workoutDay.sections.fold<int>(
        0, (sum, s) => sum + s.exercises.length);
    final completedExercises =
        completions.values.where((v) => v).length;
    final dateStr = ref.watch(dateStringProvider);
    final isFinished = ref.watch(workoutRepoProvider).isWorkoutFinished(dateStr, dayId);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workoutDay.label ?? workoutDay.dayId,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '$completedExercises/$totalExercises exercises done',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isFinished)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: totalExercises > 0
                      ? completedExercises / totalExercises
                      : 0,
                  backgroundColor: AppColors.lavender,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.green),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sections
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: workoutDay.sections.length,
                itemBuilder: (context, sectionIndex) {
                  final section = workoutDay.sections[sectionIndex];
                  return _SectionWidget(
                    section: section,
                    dayId: dayId,
                    completions: completions,
                  );
                },
              ),
            ),

            // Finish Workout Button
            if (!isFinished)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _finishWorkout(context, ref, dayId, completedExercises, totalExercises),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            color: AppColors.white, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Finish Workout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _finishWorkout(BuildContext context, WidgetRef ref, String dayId, int completed, int total) {
    if (completed < total) {
      if (completed == 0) {
        _showSkipConfirmation(context, ref, dayId);
      } else {
        _showPartialConfirmation(context, ref, dayId, completed, total);
      }
    } else {
      _executeFinish(context, ref, dayId);
    }
  }

  void _showPartialConfirmation(BuildContext context, WidgetRef ref, String dayId, int completed, int total) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish early?'),
        content: Text('Only $completed of $total exercises done — finish anyway?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeFinish(context, ref, dayId);
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  void _showSkipConfirmation(BuildContext context, WidgetRef ref, String dayId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip workout?'),
        content: const Text('Nothing checked — mark this workout as skipped instead?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final dateStr = ref.read(dateStringProvider);
              ref.read(workoutRepoProvider).finishWorkout(dateStr, dayId);
              // Do NOT mark as completed in daily log so it doesn't get the green dot
              context.go('/home');
            },
            child: const Text('Skip Workout'),
          ),
        ],
      ),
    );
  }

  void _executeFinish(BuildContext context, WidgetRef ref, String dayId) {
    final dateStr = ref.read(dateStringProvider);
    ref.read(workoutRepoProvider).finishWorkout(dateStr, dayId);
    ref.read(dailyLogProvider.notifier).markWorkoutCompleted(dayId);

    // Show celebration dialog
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Workout Complete!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Great job! Keep up the consistency.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/home');
                  },
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionWidget extends StatelessWidget {
  const _SectionWidget({
    required this.section,
    required this.dayId,
    required this.completions,
  });

  final WorkoutSection section;
  final String dayId;
  final Map<String, bool> completions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  section.title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          // Exercises
          ...List.generate(section.exercises.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Rest timer between exercises
              final exerciseIndex = index ~/ 2;
              final exercise = section.exercises[exerciseIndex];
              if (exercise.restSecondsAfterSet > 0) {
                return RestTimerLabel(
                  seconds: exercise.restSecondsAfterSet,
                );
              }
              return const SizedBox(height: 4);
            }
            final exerciseIndex = index ~/ 2;
            final exercise = section.exercises[exerciseIndex];
            final isCompleted = completions[exercise.name] ?? false;
            return ExerciseCard(
              exercise: exercise,
              dayId: dayId,
              isCompleted: isCompleted,
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
