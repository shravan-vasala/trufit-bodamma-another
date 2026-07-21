import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';

class WeightEntryDialog extends ConsumerStatefulWidget {
  const WeightEntryDialog({super.key});

  @override
  ConsumerState<WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends ConsumerState<WeightEntryDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final log = ref.read(dailyLogProvider);
    if (log.weight != null) {
      _controller.text = log.weight!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
              'Log Body Weight',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your weight for today',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight.withValues(alpha: 0.5),
                ),
                suffixText: 'kg',
                suffixStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    final weight = double.tryParse(_controller.text);
                    if (weight != null && weight > 0) {
                      ref.read(dailyLogProvider.notifier).updateWeight(weight);
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text(
                    'Save Weight',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
