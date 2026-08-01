import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../models/workout_plan.dart';
import '../log_data_dialog.dart';

class ExerciseCard extends ConsumerWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.dayId,
    required this.isCompleted,
  });

  final Exercise exercise;
  final String dayId;
  final bool isCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pr = ref.watch(exerciseLogRepoProvider).getPr(exercise.name);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // YouTube Thumbnail
                GestureDetector(
                  onTap: () {
                    final videoId = exercise.youtubeVideoId;
                    if (videoId != null && videoId != 'XXXX') {
                      context.push(
                        '/youtube-player?videoId=$videoId&title=${Uri.encodeComponent(exercise.displayName ?? exercise.name)}&subtitle=${Uri.encodeComponent(exercise.name)}&reps=${Uri.encodeComponent(exercise.repsDisplay)}',
                      );
                    }
                  },
                  child: Container(
                    width: 90,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (exercise.thumbnailUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: exercise.thumbnailUrl,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => const Center(
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  color: AppColors.primary,
                                  size: 30,
                                ),
                              ),
                              errorWidget: (ctx, url, error) => const Center(
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  color: AppColors.primary,
                                  size: 30,
                                ),
                              ),
                            )
                          else
                            const Center(
                              child: Icon(
                                Icons.fitness_center_rounded,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                          // Play overlay
                          if (exercise.youtubeUrl != null && exercise.youtubeUrl!.isNotEmpty)
                            Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.displayName ?? exercise.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.lavender,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Reps: ${exercise.repsDisplay}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (exercise.weightKg != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.lavender,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${exercise.weightKg} kg',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                          if (exercise.sideInfo != 'None') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                exercise.sideInfo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mintIcon,
                                ),
                              ),
                            ),
                          ],
                          if (pr != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.2), // Gold tint
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.emoji_events, size: 12, color: Color(0xFFB8860B)),
                                  const SizedBox(width: 2),
                                  Text(
                                    pr.maxWeight > 0 ? '${pr.maxWeight}kg' : '${pr.maxReps} reps',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB8860B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Checkmark
                GestureDetector(
                  onTap: () {
                    ref
                        .read(exerciseCompletionsProvider(dayId).notifier)
                        .toggle(exercise.name);
                        
                    // If newly completed and has rest, start timer
                    if (!isCompleted && exercise.restSecondsAfterSet > 0) {
                      ref.read(restTimerProvider.notifier).startTimer(
                            exercise.restSecondsAfterSet,
                            exerciseName: exercise.name,
                          );
                    } else if (isCompleted) {
                      // If un-completing, we could optionally stop the timer if it was for this exercise
                      final timerState = ref.read(restTimerProvider);
                      if (timerState.isActive && timerState.exerciseName == exercise.name) {
                        ref.read(restTimerProvider.notifier).stopTimer();
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? AppColors.green : Colors.transparent,
                      border: isCompleted
                          ? null
                          : Border.all(color: AppColors.border, width: 2),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, color: AppColors.white, size: 18)
                        : null,
                  ),
                ),
              ],
            ),
          ),

          // Coach note
          if (exercise.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exercise.note,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMedium,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Button row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => LogDataDialog(exercise: exercise),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Log Data'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () {
                        context.push(
                          '/exercise-progress?name=${Uri.encodeComponent(exercise.name)}',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Progress'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

