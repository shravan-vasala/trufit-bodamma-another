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
    final fill = Theme.of(context).brightness == Brightness.dark
        ? context.colors.scaffoldBg
        : context.colors.lavender;

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
              'Log Body Weight',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Enter your weight for today',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: context.colors.textMedium,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: context.colors.textDark,
              ),
              textAlign: TextAlign.center,
              cursorColor: context.colors.primary,
              decoration: InputDecoration(
                filled: true,
                fillColor: fill,
                hintText: '0.0',
                hintStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textLight,
                ),
                suffixText: 'kg',
                suffixStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textMedium,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.colors.primary, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final weight = double.tryParse(_controller.text);
                  if (weight != null && weight > 0) {
                    ref.read(dailyLogProvider.notifier).updateWeight(weight);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Save Weight',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.colors.onPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
