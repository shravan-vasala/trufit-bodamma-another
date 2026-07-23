import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';

class HabitsCard extends ConsumerWidget {
  const HabitsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final completions = ref.watch(habitCompletionsProvider);
    final completedCount = completions.completedCount;
    
    final selectedDateStr = ref.watch(dateStringProvider);
    final selectedDate = DateTime.parse(selectedDateStr);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final isFuture = selectedDate.isAfter(today);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'HABITS ($completedCount/${habits.length})',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...habits.map((habit) {
              final isCompleted = completions.isCompleted(habit.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: isFuture
                      ? null
                      : () {
                          ref.read(habitCompletionsProvider.notifier).toggle(habit.id);
                        },
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
                      Expanded(
                        child: Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isCompleted ? AppColors.textLight : AppColors.textDark,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      Text(
                        habit.icon,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
