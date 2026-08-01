import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';

class MealsCard extends ConsumerWidget {
  const MealsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(dailyMealLogProvider);
    final profile = ref.watch(profileProvider);
    final mealPlan = ref.watch(mealPlanProvider);
    final planName = mealPlan?.planName ?? 'Daily Meal Plan';
    
    final selectedDateStr = ref.watch(dateStringProvider);
    final selectedDate = DateTime.parse(selectedDateStr);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final isFuture = selectedDate.isAfter(today);
    final isToday = selectedDate.isAtSameMomentAs(today);

    final defaultIds = profile.customMealSlots.where((s) => s['isDefault'] == true).map((s) => s['id'] as String).toSet();
    final loggedIds = dailyLog.customSlots.keys.toSet();
    
    int totalMeals = defaultIds.length;
    if (isFuture || isToday) {
      final recurringIds = profile.customMealSlots.map((s) => s['id'] as String).toSet();
      totalMeals = recurringIds.union(loggedIds).length;
    } else {
      final customLoggedCount = loggedIds.difference(defaultIds).length;
      totalMeals = defaultIds.length + customLoggedCount;
    }

    final List<String> loggedEmojis = [];
    for (final slotId in loggedIds) {
      final log = dailyLog.customSlots[slotId];
      if (log != null && (log.items.isNotEmpty || log.photoPath != null || log.totalCalories > 0)) {
        if (log.emoji != null) {
          loggedEmojis.add(log.emoji!);
        } else {
          final profileSlot = profile.customMealSlots.firstWhere((s) => s['id'] == slotId, orElse: () => {});
          if (profileSlot.isNotEmpty) loggedEmojis.add(profileSlot['emoji'] as String);
        }
      }
    }
    final emojiDisplay = loggedEmojis.isNotEmpty ? loggedEmojis.join(' ') : '🍜';

    final completedMeals = dailyLog.loggedSlotsCount;
    final completedCal = dailyLog.totalCalories;
    final totalCal = profile.targetCalories;
    final progress = (completedCal / totalCal).clamp(0.0, 1.0);
    final isOverTarget = completedCal > totalCal;

    return Semantics(
      label: 'Meals Card. $completedMeals of $totalMeals meals logged. $completedCal of $totalCal calories consumed.',
      button: true,
      onTapHint: 'Open meals',
      child: GestureDetector(
        onTap: () => context.go('/home/meals'),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.colors.textLight.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Meals",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        planName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  emojiDisplay,
                  style: TextStyle(fontSize: 22),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: context.colors.lavender,
                valueColor: AlwaysStoppedAnimation<Color>(isOverTarget ? context.colors.orange : context.colors.green),
                minHeight: 6,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedMeals/$totalMeals meals  |  $completedCal/$totalCal Kcal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.textMedium,
                          ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        _MacroPill(label: 'P', value: '${dailyLog.totalProtein.toStringAsFixed(0)}g', color: context.colors.green),
                        SizedBox(width: 6),
                        _MacroPill(label: 'C', value: '${dailyLog.totalCarbs.toStringAsFixed(0)}g', color: context.colors.orange),
                        SizedBox(width: 6),
                        _MacroPill(label: 'F', value: '${dailyLog.totalFat.toStringAsFixed(0)}g', color: context.colors.primary),
                      ],
                    ),
                  ],
                ),
                if (!isFuture)
                  ExcludeSemantics(
                    child: GestureDetector(
                      onTap: () {
                         context.go('/home/meals');
                      },
                      child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 14,
                            color: context.colors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Log Food',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
