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
      builder: (_) => const AddMealSlotDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(dailyMealLogProvider);
    final profile = ref.watch(profileProvider);
    final mealPlanAsync = ref.watch(mealPlanProvider);
    final planName = mealPlanAsync.valueOrNull?.planName ?? 'Meals Plan';
    final title = profile.name.isEmpty ? planName : "${profile.name}'s $planName";
    
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
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isOverTarget 
                ? const LinearGradient(colors: [AppColors.orange, AppColors.orange])
                : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isOverTarget ? AppColors.orange.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('CALORIES', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${dailyLog.totalCalories}', style: const TextStyle(color: AppColors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    Text(' / $targetCalories Kcal', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MacroInfo(label: 'Protein', value: '${dailyLog.totalProtein.toStringAsFixed(0)}g'),
                    Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.3)),
                    _MacroInfo(label: 'Carbs', value: '${dailyLog.totalCarbs.toStringAsFixed(0)}g'),
                    Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.3)),
                    _MacroInfo(label: 'Fat', value: '${dailyLog.totalFat.toStringAsFixed(0)}g'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Meal Slots
          ...slotsToDisplay.map((s) => _MealSlotCard(
                slotId: s.id,
                slotName: s.name,
                slotEmoji: s.emoji,
                slotLog: dailyLog.customSlots[s.id],
              )),

          const SizedBox(height: 16),
          OutlinedButton.icon(
             onPressed: () => _openAddSlotDialog(context),
             icon: const Icon(Icons.add_rounded, size: 18),
             label: const Text('Add another meal', style: TextStyle(fontWeight: FontWeight.w600)),
             style: OutlinedButton.styleFrom(
               foregroundColor: AppColors.textMedium,
               side: BorderSide(color: AppColors.border),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               padding: const EdgeInsets.symmetric(vertical: 16),
             ),
          ),
        ],
      ),
    );
  }
}

class _MacroInfo extends StatelessWidget {
  const _MacroInfo({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(slotEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(child: Text(slotName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                if (hasLog)
                  Text('${slotLog!.totalCalories} Kcal', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                if (hasLog) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 20),
                ] else if (slotLog != null) ...[
                  // Slot exists but is empty (e.g. one-off slot created but not logged yet)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMedium),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                    if (slotLog!.photoPath != null) const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: slotLog!.items.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(8)),
                            child: Text('${item.name} · ${item.portion}', style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textLight, size: 14),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openScanner(context, false),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Scan Food'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openScanner(context, true),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Add Manually'),
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
