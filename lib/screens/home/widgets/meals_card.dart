import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';

class MealsCard extends ConsumerWidget {
  const MealsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlan = ref.watch(mealPlanWithCompletionsProvider);

    if (mealPlan == null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No meal plan assigned',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final completedMeals = mealPlan.completedMeals;
    final totalMeals = mealPlan.meals.length;
    final completedCal = mealPlan.completedCalories;
    final totalCal = mealPlan.totalCalories;
    final progress = totalMeals > 0 ? completedMeals / totalMeals : 0.0;

    return GestureDetector(
      onTap: () => context.go('/home/meals'),
      child: Card(
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
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: AppColors.green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEALS',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textLight,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mealPlan.planName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textLight,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.lavender,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$completedMeals/$totalMeals meals  |  $completedCal/$totalCal Kcal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
