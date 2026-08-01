import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';

class SleepEntryDialog extends ConsumerStatefulWidget {
  const SleepEntryDialog({super.key});

  @override
  ConsumerState<SleepEntryDialog> createState() => _SleepEntryDialogState();
}

class _SleepEntryDialogState extends ConsumerState<SleepEntryDialog> {
  final _controller = TextEditingController();
  TimeOfDay? _bedtime;
  TimeOfDay? _waketime;
  bool _hasExistingEntry = false;

  @override
  void initState() {
    super.initState();
    final log = ref.read(dailyLogProvider);
    if (log.sleepHours != null) {
      _controller.text = log.sleepHours!.toStringAsFixed(1);
      _hasExistingEntry = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateDurationFromTimes() {
    if (_bedtime == null || _waketime == null) return;
    
    // Compute duration
    double bedHours = _bedtime!.hour + _bedtime!.minute / 60.0;
    double wakeHours = _waketime!.hour + _waketime!.minute / 60.0;
    
    double duration = wakeHours - bedHours;
    if (duration < 0) {
      duration += 24.0;
    }
    
    _controller.text = duration.toStringAsFixed(1);
  }

  Future<void> _pickTime(bool isBedtime) async {
    final initialTime = isBedtime 
        ? (_bedtime ?? TimeOfDay(hour: 22, minute: 0)) 
        : (_waketime ?? TimeOfDay(hour: 6, minute: 0));
        
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (time != null) {
      setState(() {
        if (isBedtime) {
          _bedtime = time;
        } else {
          _waketime = time;
        }
      });
      _updateDurationFromTimes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateStr = ref.watch(dateStringProvider);
    final selectedDate = DateTime.parse(selectedDateStr);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final isFuture = selectedDate.isAfter(today);
    final dateFormatted = DateFormat('EEE, d MMM').format(selectedDate);
    
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Sleep',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textDark,
                  ),
                ),
                if (_hasExistingEntry)
                  TextButton(
                    onPressed: () {
                      ref.read(dailyLogProvider.notifier).clearSleep();
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.pink,
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 0),
                    ),
                    child: Text('Clear entry'),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Enter your sleep for $dateFormatted',
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textMedium,
              ),
            ),
            SizedBox(height: 24),
            
            // Mode 1: Hours field
            TextField(
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: context.colors.textDark,
              ),
              textAlign: TextAlign.center,
              enabled: !isFuture,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? context.colors.scaffoldBg
                    : context.colors.lavender,
                hintText: '0.0',
                hintStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textLight,
                ),
                suffixText: 'hrs',
                suffixStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textMedium,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Mode 2: Time Pickers
            Text(
              'Or calculate from times:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.textMedium,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimePickerCard(
                    title: 'Bedtime',
                    time: _bedtime,
                    onTap: isFuture ? null : () => _pickTime(true),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _TimePickerCard(
                    title: 'Wake up',
                    time: _waketime,
                    onTap: isFuture ? null : () => _pickTime(false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: isFuture ? null : context.colors.primaryGradient,
                  color: isFuture ? context.colors.divider : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isFuture ? null : [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isFuture ? null : () {
                    final sleepHours = double.tryParse(_controller.text);
                    if (sleepHours != null && sleepHours >= 0 && sleepHours <= 16) {
                      ref.read(dailyLogProvider.notifier).updateSleep(sleepHours);
                      Navigator.of(context).pop();
                    } else if (sleepHours != null && sleepHours > 16) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a value between 0 and 16 hours')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text(
                    isFuture ? 'Cannot log for future date' : 'Save Sleep',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isFuture ? context.colors.textLight : context.colors.onPrimary,
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

class _TimePickerCard extends StatelessWidget {
  const _TimePickerCard({
    required this.title,
    required this.time,
    required this.onTap,
  });

  final String title;
  final TimeOfDay? time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.colors.textMedium,
              ),
            ),
            SizedBox(height: 4),
            Text(
              time != null ? time!.format(context) : '--:--',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: time != null ? context.colors.textDark : context.colors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
