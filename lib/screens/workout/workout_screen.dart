import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/workout_plan.dart';
import 'widgets/exercise_card.dart';
import 'widgets/rest_timer_label.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.dayId,
    this.sectionIndex,
  });

  final String dayId;
  /// null = show all sections; 0+ = show that specific section only
  final int? sectionIndex;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  /// When non-null, only show that section. When null, show all.
  int? _activeSectionIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _activeSectionIndex = widget.sectionIndex;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(workoutPlanProvider);
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('No workout plan found')),
      );
    }

    WorkoutDay? day;
    for (final d in plan.days) {
      if (d.dayId == widget.dayId) {
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

    final completions = ref.watch(exerciseCompletionsProvider(widget.dayId));
    final totalExercises = workoutDay.sections
        .fold<int>(0, (sum, s) => sum + s.exercises.length);
    final completedExercises = completions.values.where((v) => v).length;
    final dateStr = ref.watch(dateStringProvider);
    final isFinished =
        ref.watch(workoutRepoProvider).isWorkoutFinished(dateStr, widget.dayId);

    // Determine which sections to display
    final bool isFiltered = _activeSectionIndex != null &&
        _activeSectionIndex! >= 0 &&
        _activeSectionIndex! < workoutDay.sections.length;
    final sectionsToShow = isFiltered
        ? [workoutDay.sections[_activeSectionIndex!]]
        : workoutDay.sections;

    // Title: use section name when filtered, day label when showing all
    final String appBarTitle = isFiltered
        ? workoutDay.sections[_activeSectionIndex!].title
        : workoutDay.label ?? workoutDay.dayId;

    // Progress counts for current view
    final viewExercises = isFiltered
        ? workoutDay.sections[_activeSectionIndex!].exercises.length
        : totalExercises;
    final viewCompleted = isFiltered
        ? workoutDay.sections[_activeSectionIndex!].exercises
            .where((e) => completions[e.name] ?? false)
            .length
        : completedExercises;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
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
                          appBarTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '$viewCompleted/$viewExercises exercises done',
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
                          Icon(Icons.check_circle,
                              color: AppColors.green, size: 16),
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

            // ── Progress bar (always total day progress) ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value:
                      totalExercises > 0 ? completedExercises / totalExercises : 0,
                  backgroundColor: AppColors.lavender,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.green),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (totalExercises > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Day total: $completedExercises/$totalExercises',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // ── "Show all sections" banner when filtered ─────────────────
            if (isFiltered)
              GestureDetector(
                onTap: () => setState(() => _activeSectionIndex = null),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.lavenderCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.grid_view_rounded,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Showing: ${workoutDay.sections[_activeSectionIndex!].title}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Show all →',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Sections list ─────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: sectionsToShow.length,
                itemBuilder: (context, listIndex) {
                  // Map back to original section index for consistency
                  final sectionIndex = isFiltered
                      ? _activeSectionIndex!
                      : listIndex;
                  final section = sectionsToShow[listIndex];
                  return _SectionWidget(
                    section: section,
                    sectionIndex: sectionIndex,
                    dayId: widget.dayId,
                    completions: completions,
                  );
                },
              ),
            ),

            // ── Finish Workout Button ─────────────────────────────────────
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
                    onPressed: () => _finishWorkout(context, ref, widget.dayId,
                        completedExercises, totalExercises),
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

  void _finishWorkout(BuildContext context, WidgetRef ref, String dayId,
      int completed, int total) {
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

  void _showPartialConfirmation(BuildContext context, WidgetRef ref,
      String dayId, int completed, int total) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish early?'),
        content:
            Text('Only $completed of $total exercises done — finish anyway?'),
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

  void _showSkipConfirmation(
      BuildContext context, WidgetRef ref, String dayId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip workout?'),
        content: const Text(
            'Nothing checked — mark this workout as skipped instead?'),
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

// ─── Section Widget ───────────────────────────────────────────────────────────

class _SectionWidget extends StatelessWidget {
  const _SectionWidget({
    required this.section,
    required this.sectionIndex,
    required this.dayId,
    required this.completions,
  });

  final WorkoutSection section;
  final int sectionIndex;
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
          // Sticky-style section header
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
                const Spacer(),
                Text(
                  '${section.exercises.length} exercises',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          // Exercises
          ...List.generate(section.exercises.length * 2 - 1, (index) {
            if (index.isOdd) {
              final exerciseIndex = index ~/ 2;
              final exercise = section.exercises[exerciseIndex];
              if (exercise.restSecondsAfterSet > 0) {
                return RestTimerLabel(
                  seconds: exercise.restSecondsAfterSet,
                  exerciseName: exercise.name,
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
