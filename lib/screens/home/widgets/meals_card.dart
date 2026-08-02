import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_insets.dart';
import '../../../providers/app_providers.dart';
import '../../../models/meal_plan.dart';
import '../../../utils/meal_plan_complete.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/surface_card.dart';
import 'photo_calorie_scanner_sheet.dart';

class MealsCard extends ConsumerWidget {
  const MealsCard({super.key});

  void _openLogSheet(
    BuildContext context, {
    required String slotId,
    required String slotName,
    required bool describe,
  }) {
    HapticFeedback.selectionClick();
    showAppBottomSheet(
      context: context,
      builder: (_) => PhotoCalorieScannerSheet(
        slotId: slotId,
        slotDisplayName: slotName,
        isManualEntry: describe,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(dailyMealLogProvider);
    final profile = ref.watch(profileProvider);
    final mealPlan = ref.watch(mealPlanProvider);
    final planName = mealPlan?.planName ?? 'Daily Meal Plan';

    final selectedDateStr = ref.watch(dateStringProvider);
    final selectedDate = DateTime.parse(selectedDateStr);
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final isFuture = selectedDate.isAfter(today);
    final isToday = selectedDate.isAtSameMomentAs(today);

    final defaultIds = profile.customMealSlots
        .where((s) => s['isDefault'] == true)
        .map((s) => s['id'] as String)
        .toSet();
    final loggedIds = dailyLog.customSlots.keys.toSet();

    int totalMeals = defaultIds.length;
    if (isFuture || isToday) {
      final recurringIds =
          profile.customMealSlots.map((s) => s['id'] as String).toSet();
      totalMeals = recurringIds.union(loggedIds).length;
    } else {
      final customLoggedCount = loggedIds.difference(defaultIds).length;
      totalMeals = defaultIds.length + customLoggedCount;
    }

    final slots = <({String id, String name, String emoji})>[];
    for (final s in profile.customMealSlots) {
      slots.add((
        id: s['id'] as String,
        name: s['name'] as String,
        emoji: s['emoji'] as String,
      ));
    }

    final completedMeals = dailyLog.loggedSlotsCount;
    final completedCal = dailyLog.totalCalories;
    final totalCal = profile.targetCalories;
    final progress = (completedCal / totalCal).clamp(0.0, 1.0);
    final isOverTarget = completedCal > totalCal;

    String nextLabel = 'Open plan';
    for (final s in slots) {
      final log = dailyLog.customSlots[s.id];
      if (!MealPlanComplete.isSlotLogged(log)) {
        nextLabel = 'Next: ${s.name}';
        break;
      }
    }

    return Semantics(
      label:
          'Meals Card. $completedMeals of $totalMeals meals logged. $completedCal of $totalCal calories consumed.',
      child: SurfaceCard(
        margin: EdgeInsets.symmetric(horizontal: kScreenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.go('/home/meals');
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
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
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textLight,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: context.colors.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverTarget ? context.colors.orange : context.colors.green,
                ),
                minHeight: 6,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '$completedMeals/$totalMeals meals  ·  $completedCal/$totalCal kcal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textMedium,
                  ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                _MacroPill(
                  label: 'P',
                  value: '${dailyLog.totalProtein.toStringAsFixed(0)}g',
                  color: context.colors.green,
                ),
                SizedBox(width: 6),
                _MacroPill(
                  label: 'C',
                  value: '${dailyLog.totalCarbs.toStringAsFixed(0)}g',
                  color: context.colors.orange,
                ),
                SizedBox(width: 6),
                _MacroPill(
                  label: 'F',
                  value: '${dailyLog.totalFat.toStringAsFixed(0)}g',
                  color: context.colors.primary,
                ),
              ],
            ),
            if (slots.isNotEmpty) ...[
              SizedBox(height: 14),
              ...slots.map((s) {
                final log = dailyLog.customSlots[s.id];
                final planned = MealPlanComplete.plannedForSlot(mealPlan, s.id);
                final logged = MealPlanComplete.isSlotLogged(log);
                final plannedDone = MealPlanComplete.isPlannedComplete(log);
                return _HomeMealSlotRow(
                  emoji: s.emoji,
                  name: s.name,
                  logged: logged,
                  plannedDone: plannedDone,
                  plannedCalories: planned?.calories,
                  showLogActions: !isFuture && !logged,
                  showAsPlanned: !isFuture && planned != null && !logged,
                  onOpen: () {
                    HapticFeedback.selectionClick();
                    context.go('/home/meals');
                  },
                  onPhoto: () => _openLogSheet(
                    context,
                    slotId: s.id,
                    slotName: s.name,
                    describe: false,
                  ),
                  onDescribe: () => _openLogSheet(
                    context,
                    slotId: s.id,
                    slotName: s.name,
                    describe: true,
                  ),
                  onAsPlanned: planned == null
                      ? null
                      : () => _completeAsPlanned(
                            ref,
                            planned,
                            s.id,
                            s.name,
                            s.emoji,
                          ),
                );
              }),
            ],
            if (!isFuture) ...[
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/home/meals');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    nextLabel,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _completeAsPlanned(
    WidgetRef ref,
    Meal planned,
    String slotId,
    String slotName,
    String slotEmoji,
  ) async {
    final profile = ref.read(profileProvider);
    final log = MealPlanComplete.buildSlotLog(
      planned: planned,
      slotName: slotName,
      slotEmoji: slotEmoji,
      profile: profile,
    );
    HapticFeedback.mediumImpact();
    await ref.read(dailyMealLogProvider.notifier).saveMealSlot(slotId, log);
  }
}

class _HomeMealSlotRow extends StatelessWidget {
  const _HomeMealSlotRow({
    required this.emoji,
    required this.name,
    required this.logged,
    required this.plannedDone,
    required this.showLogActions,
    required this.showAsPlanned,
    required this.onOpen,
    required this.onPhoto,
    required this.onDescribe,
    this.plannedCalories,
    this.onAsPlanned,
  });

  final String emoji;
  final String name;
  final bool logged;
  final bool plannedDone;
  final bool showLogActions;
  final bool showAsPlanned;
  final int? plannedCalories;
  final VoidCallback onOpen;
  final VoidCallback onPhoto;
  final VoidCallback onDescribe;
  final VoidCallback? onAsPlanned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(emoji, style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textDark,
                        decoration:
                            plannedDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (logged)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: context.colors.green,
                    )
                  else if (plannedCalories != null)
                    Text(
                      '~$plannedCalories kcal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textLight,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showLogActions) ...[
            SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: CompactButton(
                    label: 'Photo',
                    icon: Icons.camera_alt_rounded,
                    filled: true,
                    onPressed: onPhoto,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CompactButton(
                    label: 'Describe',
                    icon: Icons.notes_rounded,
                    onPressed: onDescribe,
                  ),
                ),
                if (showAsPlanned && onAsPlanned != null) ...[
                  SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Completed as planned',
                    onPressed: onAsPlanned,
                    icon: Icon(
                      Icons.check_box_outlined,
                      size: 22,
                      color: context.colors.textMedium,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.value,
    required this.color,
  });
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
