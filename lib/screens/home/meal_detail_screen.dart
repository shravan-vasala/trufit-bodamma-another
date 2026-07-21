import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/meal_plan.dart';
import '../../models/scanned_meal_log.dart';
import 'widgets/photo_calorie_scanner_sheet.dart';

class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlan = ref.watch(mealPlanWithCompletionsProvider);
    final dateStr = ref.watch(dateStringProvider);
    final scannedMeals =
        ref.watch(photoMealRepoProvider).getScannedMealsForDate(dateStr);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(mealPlan?.planName ?? 'Meal Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const PhotoCalorieScannerSheet(),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.center_focus_strong_rounded, color: AppColors.white),
        label: const Text(
          'Scan Food Photo',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: mealPlan == null
          ? const Center(child: Text('No meal plan assigned'))
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              children: [
                // Summary card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem(
                        label: 'Meals Completed',
                        value: '${mealPlan.completedMeals}/${mealPlan.meals.length}',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.white.withValues(alpha: 0.3),
                      ),
                      _SummaryItem(
                        label: 'Target Calories',
                        value: '${mealPlan.completedCalories}/${mealPlan.totalCalories}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // AI Scan Banner CTA
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const PhotoCalorieScannerSheet(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Photo Calorie Counter 📸',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Take a picture of your food to auto-count calories',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Scanned Meals Section (if any photos logged today)
                if (scannedMeals.isNotEmpty) ...[
                  const Text(
                    'SCANNED FOOD PHOTOS TODAY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...scannedMeals.map((scanned) => _ScannedMealCard(log: scanned)),
                  const SizedBox(height: 20),
                ],

                // Scheduled Meal Plan Section
                const Text(
                  'SCHEDULED MEAL PLAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // Meal cards
                ...mealPlan.meals.map((meal) => _MealCard(meal: meal)),
              ],
            ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _ScannedMealCard extends ConsumerWidget {
  const _ScannedMealCard({required this.log});

  final ScannedMealLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Photo preview thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: kIsWeb
                ? Image.network(
                    log.photoPath,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 72,
                      height: 72,
                      color: AppColors.lavender,
                      child: const Icon(Icons.fastfood_rounded, color: AppColors.primary),
                    ),
                  )
                : Image.file(
                    File(log.photoPath),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 72,
                      height: 72,
                      color: AppColors.lavender,
                      child: const Icon(Icons.fastfood_rounded, color: AppColors.primary),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.lavender,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        log.mealType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${log.portionMultiplier.toStringAsFixed(1)}x plate',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.foodName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.totalCalories} Kcal  ·  P: ${log.totalProtein.toStringAsFixed(0)}g  C: ${log.totalCarbs.toStringAsFixed(0)}g  F: ${log.totalFat.toStringAsFixed(0)}g',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textLight, size: 20),
            onPressed: () async {
              await ref.read(photoMealRepoProvider).deleteScannedMeal(log.id);
              ref.read(refreshTriggerProvider.notifier).state++;
            },
          ),
        ],
      ),
    );
  }
}

class _MealCard extends ConsumerWidget {
  const _MealCard({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () {
              ref
                  .read(mealPlanWithCompletionsProvider.notifier)
                  .toggleMeal(meal.type);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Text(
                    meal.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${meal.calories} Kcal',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          meal.isCompleted ? AppColors.green : Colors.transparent,
                      border: meal.isCompleted
                          ? null
                          : Border.all(color: AppColors.border, width: 2),
                    ),
                    child: meal.isCompleted
                        ? const Icon(Icons.check, color: AppColors.white, size: 18)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          // Items
          if (meal.items.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: meal.items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.name} · ${item.quantity}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMedium,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
