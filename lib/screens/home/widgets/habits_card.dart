import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../models/habit.dart';
import '../../profile/manage_habits_screen.dart';
import '../sleep_entry_dialog.dart';

class HabitsCard extends ConsumerWidget {
  const HabitsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final completions = ref.watch(habitCompletionsProvider);
    final dailyLog = ref.watch(dailyLogProvider);
    
    final selectedDateStr = ref.watch(dateStringProvider);
    final selectedDate = DateTime.parse(selectedDateStr);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final isFuture = selectedDate.isAfter(today);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textLight.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < habits.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _HabitItem(
                habit: habits[i],
                isCompleted: isHabitCompleted(habits[i], completions, dailyLog),
                isFuture: isFuture,
                progress: getHabitProgress(habits[i], completions, dailyLog),
              ),
            ),
            if (i < habits.length - 1)
              Divider(height: 1, color: AppColors.textLight.withValues(alpha: 0.1)),
          ],
          if (habits.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('No habits yet. Tap the edit icon to add some!', style: TextStyle(color: AppColors.textMedium)),
              ),
            ),
        ],
      ),
    );
  }
}

class _HabitItem extends ConsumerWidget {
  final Habit habit;
  final bool isCompleted;
  final bool isFuture;
  final double progress;

  const _HabitItem({
    required this.habit,
    required this.isCompleted,
    required this.isFuture,
    required this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: isFuture ? null : () => _handleTap(context, ref),
              onLongPress: isFuture ? null : () => _handleLongPress(context, ref),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? AppColors.green : (isFuture ? AppColors.textLight.withValues(alpha: 0.1) : Colors.transparent),
                      border: isCompleted || isFuture
                          ? null
                          : Border.all(color: AppColors.border, width: 2),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, color: AppColors.white, size: 16)
                        : (isFuture ? Icon(Icons.lock_outline_rounded, color: AppColors.textLight.withValues(alpha: 0.5), size: 14) : null),
                  ),
                  const SizedBox(width: 14),
                  
                  // Habit Name & Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isCompleted ? AppColors.textLight : AppColors.textDark,
                            decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        Row(
                          children: [
                            if (habit.type != HabitType.checkbox)
                              GestureDetector(
                                onTap: (habit.type == HabitType.autoSleep && !isFuture)
                                    ? () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => const SleepEntryDialog(),
                                        );
                                      }
                                    : null,
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2, bottom: 2, right: 8),
                                  child: Text(
                                    _formatProgress(),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                                  ),
                                ),
                              ),
                            Consumer(
                              builder: (context, ref, child) {
                                final streak = ref.watch(habitStreakProvider(habit.id));
                                if (streak > 1) {
                                  return Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '🔥 $streak Day Streak',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.orange,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action / Emoji
          if (habit.type == HabitType.counter && !isFuture)
            Row(
              children: [
                _MiniButton(
                  icon: Icons.remove,
                  onTap: () {
                    final newProg = (progress - habit.step).clamp(0.0, habit.target);
                    ref.read(habitCompletionsProvider.notifier).updateProgress(habit.id, newProg);
                  },
                ),
                const SizedBox(width: 4),
                _MiniButton(
                  icon: Icons.add,
                  onTap: () {
                    final newProg = (progress + habit.step).clamp(0.0, habit.target);
                    ref.read(habitCompletionsProvider.notifier).updateProgress(habit.id, newProg);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            
          _buildIcon(habit.name, habit.icon),
        ],
    );
  }

  Widget _buildIcon(String name, String fallbackEmoji) {
    IconData? outlineIcon;
    final lowerName = name.toLowerCase();
    if (lowerName.contains('sleep')) {
      outlineIcon = Icons.bed_outlined;
    } else if (lowerName.contains('steps') || lowerName.contains('walk')) {
      outlineIcon = Icons.directions_walk_rounded;
    } else if (lowerName.contains('water') || lowerName.contains('hydrate')) {
      outlineIcon = Icons.local_drink_outlined;
    }
    
    if (outlineIcon != null) {
      return Icon(outlineIcon, color: AppColors.textLight, size: 24);
    }
    return Text(fallbackEmoji, style: const TextStyle(fontSize: 20));
  }

  String _formatProgress() {
    String pStr = progress == progress.toInt() ? progress.toInt().toString() : progress.toStringAsFixed(1);
    String tStr = habit.target == habit.target.toInt() ? habit.target.toInt().toString() : habit.target.toStringAsFixed(1);
    return '$pStr / $tStr ${habit.unit}';
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (habit.type == HabitType.checkbox) {
      ref.read(habitCompletionsProvider.notifier).toggle(habit.id);
      return;
    }
    
    final override = ref.read(habitCompletionsProvider).overrides[habit.id];
    final isSyncCompleted = isCompleted && override == null;
    
    if ((habit.type == HabitType.autoSteps || habit.type == HabitType.autoSleep) && isSyncCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completed from Samsung Health. Long press to override as not done.')),
      );
      return;
    }

    String? newOverride;
    if (isCompleted) {
      if (override == 'done') {
        newOverride = null; 
      } else {
        newOverride = 'notDone'; 
      }
    } else {
      newOverride = 'done';
    }
    
    ref.read(habitCompletionsProvider.notifier).setOverride(habit.id, newOverride);
  }

  void _handleLongPress(BuildContext context, WidgetRef ref) {
    if (habit.type != HabitType.autoSteps && habit.type != HabitType.autoSleep) return;
    
    final override = ref.read(habitCompletionsProvider).overrides[habit.id];
    final isSyncCompleted = isCompleted && override == null;
    
    if (isSyncCompleted) {
      ref.read(habitCompletionsProvider.notifier).setOverride(habit.id, 'notDone');
    }
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  
  const _MiniButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.lavender,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}
