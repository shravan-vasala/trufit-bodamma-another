import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class RestTimerLabel extends StatelessWidget {
  const RestTimerLabel({super.key, required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    if (seconds <= 0) return const SizedBox.shrink();

    final display = seconds >= 60
        ? '${seconds ~/ 60} MIN${seconds % 60 > 0 ? ' ${seconds % 60} SEC' : ''}'
        : '$seconds SEC';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(height: 1, color: AppColors.border),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'REST FOR $display AFTER SET',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(height: 1, color: AppColors.border),
          ),
        ],
      ),
    );
  }
}
