import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';

class StepsEntryDialog extends ConsumerStatefulWidget {
  const StepsEntryDialog({super.key});

  @override
  ConsumerState<StepsEntryDialog> createState() => _StepsEntryDialogState();
}

class _StepsEntryDialogState extends ConsumerState<StepsEntryDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final log = ref.read(dailyLogProvider);
    if (log.steps != null) {
      _controller.text = log.steps.toString();
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
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Log Steps',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Enter your step count for today',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: context.colors.primary,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textLight.withValues(alpha: 0.5),
                ),
                suffixText: 'steps',
                suffixStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textMedium,
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: context.colors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    final steps = int.tryParse(_controller.text);
                    if (steps != null && steps > 0) {
                      ref.read(dailyLogProvider.notifier).updateSteps(steps, source: 'manual');
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text(
                    'Save Steps',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
