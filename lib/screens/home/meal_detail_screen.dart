import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/meal_plan.dart';

class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlan = ref.watch(mealPlanWithCompletionsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(mealPlan?.planName ?? 'Meal Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: mealPlan == null
          ? const Center(child: Text('No meal plan assigned'))
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // Summary card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem(
                        label: 'Meals',
                        value: '${mealPlan.completedMeals}/${mealPlan.meals.length}',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.white.withValues(alpha: 0.3),
                      ),
                      _SummaryItem(
                        label: 'Calories',
                        value: '${mealPlan.completedCalories}/${mealPlan.totalCalories}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
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
