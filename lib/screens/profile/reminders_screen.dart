import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/reminders_provider.dart';
import '../../models/reminder_config.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  Future<void> _pickTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remindersProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Reminders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('DAILY HABITS'),
          _buildToggleCard(
            title: 'Habit Reminder',
            subtitle: 'Remind me to log my habits',
            value: config.habitsEnabled,
            onChanged: (val) {
              ref.read(remindersProvider.notifier).updateConfig(config.copyWith(habitsEnabled: val));
            },
            child: config.habitsEnabled
                ? _buildTimeSelector(
                    label: 'Time',
                    time: config.habitTime,
                    onTap: () => _pickTime(context, config.habitTime, (t) {
                      ref.read(remindersProvider.notifier).updateConfig(config.copyWith(habitTime: t));
                    }),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('WORKOUTS'),
          _buildToggleCard(
            title: 'Workout Reminder',
            subtitle: 'Remind me on scheduled workout days',
            value: config.workoutsEnabled,
            onChanged: (val) {
              ref.read(remindersProvider.notifier).updateConfig(config.copyWith(workoutsEnabled: val));
            },
            child: config.workoutsEnabled
                ? _buildTimeSelector(
                    label: 'Time',
                    time: config.workoutTime,
                    onTap: () => _pickTime(context, config.workoutTime, (t) {
                      ref.read(remindersProvider.notifier).updateConfig(config.copyWith(workoutTime: t));
                    }),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('MEALS'),
          _buildToggleCard(
            title: 'Meal Logging Nudge',
            subtitle: 'Remind me to track lunch and dinner',
            value: config.mealsEnabled,
            onChanged: (val) {
              ref.read(remindersProvider.notifier).updateConfig(config.copyWith(mealsEnabled: val));
            },
            child: config.mealsEnabled
                ? Column(
                    children: [
                      _buildTimeSelector(
                        label: 'Lunch Time',
                        time: config.lunchTime,
                        onTap: () => _pickTime(context, config.lunchTime, (t) {
                          ref.read(remindersProvider.notifier).updateConfig(config.copyWith(lunchTime: t));
                        }),
                      ),
                      const SizedBox(height: 8),
                      _buildTimeSelector(
                        label: 'Dinner Time',
                        time: config.dinnerTime,
                        onTap: () => _pickTime(context, config.dinnerTime, (t) {
                          ref.read(remindersProvider.notifier).updateConfig(config.copyWith(dinnerTime: t));
                        }),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('DATA BACKUP'),
          _buildToggleCard(
            title: 'Weekly Backup Reminder',
            subtitle: 'Remind me to export my data securely',
            value: config.backupEnabled,
            onChanged: (val) {
              ref.read(remindersProvider.notifier).updateConfig(config.copyWith(backupEnabled: val));
            },
            child: config.backupEnabled
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Day of Week', style: TextStyle(fontSize: 14, color: AppColors.textDark)),
                          DropdownButton<int>(
                            value: config.backupDayOfWeek,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                            items: const [
                              DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                              DropdownMenuItem(value: DateTime.tuesday, child: Text('Tuesday')),
                              DropdownMenuItem(value: DateTime.wednesday, child: Text('Wednesday')),
                              DropdownMenuItem(value: DateTime.thursday, child: Text('Thursday')),
                              DropdownMenuItem(value: DateTime.friday, child: Text('Friday')),
                              DropdownMenuItem(value: DateTime.saturday, child: Text('Saturday')),
                              DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(remindersProvider.notifier).updateConfig(config.copyWith(backupDayOfWeek: val));
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTimeSelector(
                        label: 'Time',
                        time: config.backupTime,
                        onTap: () => _pickTime(context, config.backupTime, (t) {
                          ref.read(remindersProvider.notifier).updateConfig(config.copyWith(backupTime: t));
                        }),
                      ),
                    ],
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (child != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.border),
            ),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector({required String label, required TimeOfDay time, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTime(time),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
