import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../weight_entry_dialog.dart';

class DailyProgressGrid extends ConsumerWidget {
  const DailyProgressGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(dailyLogProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ProgressCard(
                  title: 'Body Stats',
                  icon: Icons.straighten_rounded,
                  color: AppColors.pink,
                  iconColor: AppColors.pinkIcon,
                  subtitle: 'Tap to view',
                  onTap: () => context.go('/home/body-stats'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProgressCard(
                  title: 'Physique\nPictures',
                  icon: Icons.camera_alt_rounded,
                  color: AppColors.pink,
                  iconColor: AppColors.pinkIcon,
                  subtitle: 'Progress photos',
                  onTap: () => context.go('/home/physique-pictures'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ProgressCard(
                  title: 'Body Weight',
                  icon: Icons.monitor_weight_rounded,
                  color: AppColors.lavenderCard,
                  iconColor: AppColors.primary,
                  subtitle: dailyLog.weight != null
                      ? '${dailyLog.weight!.toStringAsFixed(1)} kg'
                      : 'Tap to log',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const WeightEntryDialog(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProgressCard(
                  title: 'Steps',
                  icon: Icons.directions_walk_rounded,
                  color: AppColors.mint,
                  iconColor: AppColors.mintIcon,
                  subtitle: dailyLog.steps != null
                      ? '${dailyLog.steps!} steps'
                      : 'Tap to log',
                  onTap: () {
                    _showStepsDialog(context, ref);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStepsDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final dailyLog = ref.read(dailyLogProvider);
    if (dailyLog.steps != null) {
      controller.text = dailyLog.steps.toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Log Steps',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Enter step count',
                  suffixText: 'steps',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final steps = int.tryParse(controller.text);
                    if (steps != null && steps > 0) {
                      ref.read(dailyLogProvider.notifier).updateSteps(steps);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
