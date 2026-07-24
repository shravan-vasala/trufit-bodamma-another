import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../models/habit.dart';
import '../../profile/manage_habits_screen.dart';

class HabitsCard extends ConsumerWidget {
  const HabitsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final completions = ref.watch(habitCompletionsProvider);
    final dailyLog = ref.watch(dailyLogProvider);
    
    final completedCount = habits.where((h) => isHabitCompleted(h, completions, dailyLog)).length;
    
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
                Expanded(
                  child: Text(
                    'HABITS ($completedCount/${habits.length})',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ManageHabitsScreen(),
                    ));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...habits.map((habit) {
              final isCompleted = isHabitCompleted(habit, completions, dailyLog);
              return _HabitItem(
                habit: habit,
                isCompleted: isCompleted,
                isFuture: isFuture,
                progress: getHabitProgress(habit, completions, dailyLog),
              );
            }),
            if (habits.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No habits yet. Tap the edit icon to add some!', style: TextStyle(color: AppColors.textMedium)),
                ),
              ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Completion Indicator (Checkbox or Circle)
          GestureDetector(
            onTap: isFuture || habit.type != HabitType.checkbox
                ? null
                : () {
                    ref.read(habitCompletionsProvider.notifier).toggle(habit.id);
                  },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
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
                if (habit.type != HabitType.checkbox)
                  Text(
                    _formatProgress(),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                  ),
              ],
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
            
          Text(habit.icon, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  String _formatProgress() {
    String pStr = progress == progress.toInt() ? progress.toInt().toString() : progress.toStringAsFixed(1);
    String tStr = habit.target == habit.target.toInt() ? habit.target.toInt().toString() : habit.target.toStringAsFixed(1);
    return '$pStr / $tStr ${habit.unit}';
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
