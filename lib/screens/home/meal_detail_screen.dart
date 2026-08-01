import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/daily_meal_log.dart';
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
    final title = planName;
    
    final targetCalories = profile.targetCalories;
    final isOverTarget = dailyLog.totalCalories > targetCalories;
    final progressRatio = (dailyLog.totalCalories / targetCalories).clamp(0.0, 1.0);

    // Compute dynamic slots to display
    final List<({String id, String name, String emoji})> slotsToDisplay = [];
    final recurringIds = <String>{};

    for (final s in profile.customMealSlots) {
      final id = s['id'] as String;
      recurringIds.add(id);
      slotsToDisplay.add((id: id, name: s['name'] as String, emoji: s['emoji'] as String));
    }

    for (final entry in dailyLog.customSlots.entries) {
      if (!recurringIds.contains(entry.key)) {
        final id = entry.key;
        final log = entry.value;
        slotsToDisplay.add((
          id: id, 
          name: log.name ?? 'Meal', 
          emoji: log.emoji ?? '🍽️'
        ));
      }
    }

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 20, 20, 80),
        children: [
          // Header Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isOverTarget 
                ? LinearGradient(colors: [context.colors.orange, context.colors.orange])
                : context.colors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isOverTarget ? context.colors.orange.withValues(alpha: 0.3) : context.colors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text('CALORIES', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${dailyLog.totalCalories}', style: TextStyle(color: context.colors.onPrimary, fontSize: 36, fontWeight: FontWeight.bold)),
                    Text(' / $targetCalories Kcal', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(context.colors.white),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _MacroInfo(label: 'Protein', current: dailyLog.totalProtein, target: profile.targetProteinG.toDouble(), color: context.colors.green)),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
                    Expanded(child: _MacroInfo(label: 'Carbs', current: dailyLog.totalCarbs, target: profile.targetCarbsG.toDouble(), color: context.colors.orange)),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
                    Expanded(child: _MacroInfo(label: 'Fat', current: dailyLog.totalFat, target: profile.targetFatG.toDouble(), color: context.colors.lavender)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Meal Slots
          ...slotsToDisplay.map((s) => _MealSlotCard(
                slotId: s.id,
                slotName: s.name,
                slotEmoji: s.emoji,
                slotLog: dailyLog.customSlots[s.id],
              )),

          SizedBox(height: 16),
          OutlinedButton.icon(
             onPressed: () => _openAddSlotDialog(context),
             icon: Icon(Icons.add_rounded, size: 18),
             label: Text('Add another meal', style: TextStyle(fontWeight: FontWeight.w600)),
             style: OutlinedButton.styleFrom(
               foregroundColor: context.colors.textMedium,
               side: BorderSide(color: context.colors.border),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               padding: EdgeInsets.symmetric(vertical: 16),
             ),
          ),
        ],
      ),
    );
  }
}

class _MacroInfo extends StatelessWidget {
  const _MacroInfo({required this.label, required this.current, required this.target, required this.color});
  final String label;
  final double current;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (current / (target > 0 ? target : 1)).clamp(0.0, 1.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text('${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}g', style: TextStyle(color: context.colors.onPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 11)),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSlotCard extends ConsumerWidget {
  const _MealSlotCard({
    required this.slotId, 
    required this.slotName, 
    required this.slotEmoji, 
    this.slotLog
  });
  
  final String slotId;
  final String slotName;
  final String slotEmoji;
  final MealSlotLog? slotLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLog = slotLog != null && (slotLog!.items.isNotEmpty || slotLog!.photoPath != null || slotLog!.totalCalories > 0);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: context.colors.primary.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(slotEmoji, style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Expanded(child: Text(slotName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textDark))),
                if (hasLog)
                  Text('${slotLog!.totalCalories} Kcal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.primary)),
                if (hasLog) ...[
                  SizedBox(width: 8),
                  Icon(Icons.check_circle_rounded, color: context.colors.green, size: 20),
                ] else if (slotLog != null) ...[
                  // Slot exists but is empty (e.g. one-off slot created but not logged yet)
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: context.colors.textMedium),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () {
                       // Delete one-off slot
                       ref.read(dailyMealLogProvider.notifier).clearMealSlot(slotId);
                    },
                  )
                ]
              ],
            ),
          ),
          // Body
          if (hasLog)
            GestureDetector(
              onTap: () => _openScanner(context, false), // reopen edit
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (slotLog!.photoPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(slotLog!.photoPath!, width: 64, height: 64, fit: BoxFit.cover)
                            : Image.file(File(slotLog!.photoPath!), width: 64, height: 64, fit: BoxFit.cover),
                      ),
                    if (slotLog!.photoPath != null) SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: slotLog!.items.map((item) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: context.colors.lavender, borderRadius: BorderRadius.circular(8)),
                            child: Text('${item.name} · ${item.portion}', style: TextStyle(fontSize: 11, color: context.colors.textDark)),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios_rounded, color: context.colors.textLight, size: 14),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openScanner(context, false),
                      icon: Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text('Scan Food'),
                      style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary, foregroundColor: context.colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openScanner(context, true),
                      icon: Icon(Icons.edit_note_rounded, size: 18),
                      label: Text('Add Manually'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openScanner(BuildContext context, bool isManualEntry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoCalorieScannerSheet(
        slotId: slotId, 
        slotDisplayName: slotName,
        isManualEntry: isManualEntry
      ),
    );
  }
}
