import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/layout_insets.dart';
import '../../providers/app_providers.dart';
import '../../models/daily_meal_log.dart';
import '../../models/meal_plan.dart';
import '../../utils/meal_plan_complete.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/surface_card.dart';
import 'widgets/photo_calorie_scanner_sheet.dart';
import 'widgets/add_meal_slot_dialog.dart';

class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({super.key});

  void _openAddSlotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddMealSlotDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(dailyMealLogProvider);
    final profile = ref.watch(profileProvider);
    final mealPlan = ref.watch(mealPlanProvider);
    final planName = mealPlan?.planName ?? 'Daily Meal Plan';

    final targetCalories = profile.targetCalories;
    final isOverTarget = dailyLog.totalCalories > targetCalories;
    final progressRatio =
        (dailyLog.totalCalories / (targetCalories > 0 ? targetCalories : 1))
            .clamp(0.0, 1.0);

    final List<({String id, String name, String emoji})> slotsToDisplay = [];
    final recurringIds = <String>{};

    for (final s in profile.customMealSlots) {
      final id = s['id'] as String;
      recurringIds.add(id);
      slotsToDisplay.add((
        id: id,
        name: s['name'] as String,
        emoji: s['emoji'] as String,
      ));
    }

    for (final entry in dailyLog.customSlots.entries) {
      if (!recurringIds.contains(entry.key)) {
        final log = entry.value;
        slotsToDisplay.add((
          id: entry.key,
          name: log.name ?? 'Meal',
          emoji: log.emoji ?? '🍽️',
        ));
      }
    }

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Today's meals"),
            Text(
              planName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.colors.textMedium,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          kShellScrollBottomPadding + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _CalorieHeader(
            eaten: dailyLog.totalCalories,
            target: targetCalories,
            progress: progressRatio,
            isOverTarget: isOverTarget,
            protein: dailyLog.totalProtein,
            carbs: dailyLog.totalCarbs,
            fat: dailyLog.totalFat,
            proteinTarget: profile.targetProteinG.toDouble(),
            carbsTarget: profile.targetCarbsG.toDouble(),
            fatTarget: profile.targetFatG.toDouble(),
          ),
          SizedBox(height: 24),
          ...slotsToDisplay.map(
            (s) => _MealSlotCard(
              slotId: s.id,
              slotName: s.name,
              slotEmoji: s.emoji,
              slotLog: dailyLog.customSlots[s.id],
              plannedMeal: MealPlanComplete.plannedForSlot(mealPlan, s.id),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openAddSlotDialog(context),
              icon: Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Add another meal',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.primary,
                backgroundColor: context.colors.primary.withValues(alpha: 0.08),
                side: BorderSide(
                  color: context.colors.primary.withValues(alpha: 0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieHeader extends StatelessWidget {
  const _CalorieHeader({
    required this.eaten,
    required this.target,
    required this.progress,
    required this.isOverTarget,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
  });

  final int eaten;
  final int target;
  final double progress;
  final bool isOverTarget;
  final double protein;
  final double carbs;
  final double fat;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;

  @override
  Widget build(BuildContext context) {
    final accent = isOverTarget ? context.colors.orange : context.colors.primary;

    return SurfaceCard(
      elevation: SurfaceCardElevation.nested,
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 112,
                  height: 112,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$eaten',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textDark,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'of $target kcal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textMedium,
                  ),
                ),
                if (isOverTarget) ...[
                  SizedBox(height: 2),
                  Text(
                    '+${eaten - target} over',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.colors.orange,
                    ),
                  ),
                ],
                SizedBox(height: 14),
                _MacroBar(
                  label: 'Protein',
                  current: protein,
                  target: proteinTarget,
                  color: context.colors.green,
                ),
                SizedBox(height: 10),
                _MacroBar(
                  label: 'Carbs',
                  current: carbs,
                  target: carbsTarget,
                  color: context.colors.orange,
                ),
                SizedBox(height: 10),
                _MacroBar(
                  label: 'Fat',
                  current: fat,
                  target: fatTarget,
                  color: context.colors.indigo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  final String label;
  final double current;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = (current / (target > 0 ? target : 1)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textMedium,
                ),
              ),
            ),
            Text(
              '${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)}g',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.colors.textDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: context.colors.primary.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _MealSlotCard extends ConsumerStatefulWidget {
  const _MealSlotCard({
    required this.slotId,
    required this.slotName,
    required this.slotEmoji,
    this.slotLog,
    this.plannedMeal,
  });

  final String slotId;
  final String slotName;
  final String slotEmoji;
  final MealSlotLog? slotLog;
  final Meal? plannedMeal;

  @override
  ConsumerState<_MealSlotCard> createState() => _MealSlotCardState();
}

class _MealSlotCardState extends ConsumerState<_MealSlotCard> {
  bool _showSuggested = false;

  bool get _hasLog => MealPlanComplete.isSlotLogged(widget.slotLog);

  bool get _isPlannedComplete =>
      MealPlanComplete.isPlannedComplete(widget.slotLog);

  @override
  Widget build(BuildContext context) {
    final planned = widget.plannedMeal;
    final slotLog = widget.slotLog;

    return SurfaceCard(
      margin: EdgeInsets.only(bottom: 16),
      elevation: SurfaceCardElevation.nested,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(widget.slotEmoji, style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.slotName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textDark,
                        ),
                      ),
                      if (!_hasLog &&
                          planned != null &&
                          planned.calories > 0) ...[
                        SizedBox(height: 2),
                        Text(
                          'Target ~${planned.calories} kcal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_hasLog)
                  Text(
                    '${slotLog!.totalCalories} kcal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                    ),
                  ),
                if (_hasLog) ...[
                  SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    color: context.colors.green,
                    size: 20,
                  ),
                ] else if (slotLog != null) ...[
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: context.colors.textMedium,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () {
                      ref
                          .read(dailyMealLogProvider.notifier)
                          .clearMealSlot(widget.slotId);
                    },
                  ),
                ],
              ],
            ),
          ),

          // Logged non-planned content
          if (_hasLog && !_isPlannedComplete)
            GestureDetector(
              onTap: () => _openScanner(context, false),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (slotLog!.photoPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(
                                slotLog.photoPath!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(slotLog.photoPath!),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                      ),
                    if (slotLog.photoPath != null) SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: slotLog.items.map((item) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.lavender,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.name} · ${item.portion}',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.colors.textDark,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: context.colors.textLight,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),

          // Photo & describe first — home cooking primary path
          if (!_hasLog)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CompactButton(
                          label: 'Take photo',
                          icon: Icons.camera_alt_rounded,
                          filled: true,
                          onPressed: () => _openScanner(context, false),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: CompactButton(
                          label: 'Describe',
                          icon: Icons.notes_rounded,
                          onPressed: () => _openScanner(context, true),
                        ),
                      ),
                    ],
                  ),
                  if (planned != null)
                    TextButton(
                      onPressed: () => _toggleCompletedAsPlanned(planned),
                      child: Text(
                        'Or mark completed as planned',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textMedium,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else if (_isPlannedComplete)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: CompactButton(
                      label: 'Replace with photo',
                      icon: Icons.camera_alt_rounded,
                      onPressed: () => _openScanner(context, false),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: CompactButton(
                      label: 'Describe',
                      icon: Icons.notes_rounded,
                      onPressed: () => _openScanner(context, true),
                    ),
                  ),
                ],
              ),
            ),

          // Suggested plan items — collapsed by default (optional reference)
          if (planned != null && planned.items.isNotEmpty)
            _SuggestedPlanSection(
              expanded: _showSuggested,
              onToggle: () => setState(() => _showSuggested = !_showSuggested),
              items: planned.items,
              strikethrough: _isPlannedComplete,
            ),

          if (planned != null && _hasLog && !_isPlannedComplete)
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 12, 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleCompletedAsPlanned(planned),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_box_outline_blank_rounded,
                        color: context.colors.textMedium,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Switch to completed as planned',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (planned != null && _isPlannedComplete)
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 12, 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleCompletedAsPlanned(planned),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_box_rounded,
                        color: context.colors.green,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Completed as planned',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _toggleCompletedAsPlanned(Meal planned) async {
    final notifier = ref.read(dailyMealLogProvider.notifier);
    if (_isPlannedComplete) {
      HapticFeedback.selectionClick();
      await notifier.clearMealSlot(widget.slotId);
      return;
    }

    final profile = ref.read(profileProvider);
    final log = MealPlanComplete.buildSlotLog(
      planned: planned,
      slotName: widget.slotName,
      slotEmoji: widget.slotEmoji,
      profile: profile,
    );

    HapticFeedback.mediumImpact();
    await notifier.saveMealSlot(widget.slotId, log);
  }

  void _openScanner(BuildContext context, bool isManualEntry) {
    showAppBottomSheet(
      context: context,
      builder: (_) => PhotoCalorieScannerSheet(
        slotId: widget.slotId,
        slotDisplayName: widget.slotName,
        isManualEntry: isManualEntry,
      ),
    );
  }
}

class _SuggestedPlanSection extends StatelessWidget {
  const _SuggestedPlanSection({
    required this.expanded,
    required this.onToggle,
    required this.items,
    required this.strikethrough,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final List<MealItem> items;
  final bool strikethrough;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: context.colors.textLight,
                  ),
                  SizedBox(width: 4),
                  Text(
                    expanded ? 'Hide suggested' : 'Suggested (optional)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 8, 4),
              child: Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: strikethrough
                                      ? context.colors.green
                                      : context.colors.primary
                                          .withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.textMedium,
                                  decoration: strikethrough
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: context.colors.textMedium,
                                ),
                              ),
                            ),
                            Text(
                              item.quantity,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
