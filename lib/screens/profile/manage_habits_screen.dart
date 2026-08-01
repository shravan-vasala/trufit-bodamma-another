import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/habit.dart';

class ManageHabitsScreen extends ConsumerStatefulWidget {
  const ManageHabitsScreen({super.key});

  @override
  ConsumerState<ManageHabitsScreen> createState() => _ManageHabitsScreenState();
}

class _ManageHabitsScreenState extends ConsumerState<ManageHabitsScreen> {
  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Manage Habits'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: AppColors.primary),
            tooltip: 'Remind me daily',
            onPressed: () => context.go('/profile/reminders'),
          ),
        ],
      ),
      body: habits.isEmpty
          ? const Center(child: Text('No habits found. Add one!'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: habits.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                final list = List<Habit>.from(habits);
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                ref.read(habitRepoProvider).reorderHabits(list).then((_) {
                  ref.read(refreshTriggerProvider.notifier).state++;
                });
              },
              itemBuilder: (context, index) {
                final habit = habits[index];
                return _HabitListTile(
                  key: ValueKey(habit.id),
                  habit: habit,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditorDialog(context, ref, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text('Add Habit', style: TextStyle(color: AppColors.white)),
      ),
    );
  }

  void _showEditorDialog(BuildContext context, WidgetRef ref, Habit? habit) {
    showDialog(
      context: context,
      builder: (ctx) => _HabitEditorDialog(habit: habit),
    );
  }
}

class _HabitListTile extends ConsumerWidget {
  final Habit habit;
  const _HabitListTile({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Text(habit.icon, style: const TextStyle(fontSize: 24)),
        title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_getTypeDescription(habit)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => _HabitEditorDialog(habit: habit),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Habit?'),
                    content: const Text('Are you sure you want to delete this habit? History will be kept for past days, but it won\'t appear anymore.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          ref.read(habitRepoProvider).deleteHabit(habit.id).then((_) {
                            if (!context.mounted) return;
                            ref.read(refreshTriggerProvider.notifier).state++;
                            Navigator.pop(ctx);
                          });
                        },
                        child: const Text('Delete', style: TextStyle(color: AppColors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            const Icon(Icons.drag_handle_rounded, color: AppColors.textMedium),
          ],
        ),
      ),
    );
  }

  String _getTypeDescription(Habit h) {
    switch (h.type) {
      case HabitType.checkbox:
        return 'Checkbox';
      case HabitType.counter:
        return 'Counter (Target: ${h.target} ${h.unit})';
      case HabitType.autoSteps:
        return 'Auto from Steps (Target: ${h.target})';
      case HabitType.autoSleep:
        return 'From sleep log (Target: ${h.target} hrs)';
    }
  }
}

class _HabitEditorDialog extends ConsumerStatefulWidget {
  final Habit? habit;
  const _HabitEditorDialog({this.habit});

  @override
  ConsumerState<_HabitEditorDialog> createState() => _HabitEditorDialogState();
}

class _HabitEditorDialogState extends ConsumerState<_HabitEditorDialog> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _stepCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  
  String _selectedEmoji = '✅';
  HabitType _type = HabitType.checkbox;

  final _emojis = ['✅', '🧘', '😴', '🚶', '💧', '📚', '💊', '🍎', '🏃', '🏋️', '🚭', '🥦'];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      final h = widget.habit!;
      _nameCtrl.text = h.name;
      _selectedEmoji = h.icon;
      _type = h.type;
      _targetCtrl.text = h.target.toString();
      _stepCtrl.text = h.step.toString();
      _unitCtrl.text = h.unit;
    } else {
      _targetCtrl.text = '1';
      _stepCtrl.text = '1';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _stepCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final target = double.tryParse(_targetCtrl.text) ?? 1.0;
    final step = double.tryParse(_stepCtrl.text) ?? 1.0;

    final isNew = widget.habit == null;
    final id = isNew ? DateTime.now().millisecondsSinceEpoch.toString() : widget.habit!.id;

    final updated = Habit(
      id: id,
      name: name,
      icon: _selectedEmoji,
      type: _type,
      target: target,
      step: step,
      unit: _unitCtrl.text.trim(),
      createdAt: isNew ? DateTime.now() : widget.habit!.createdAt,
      order: isNew ? ref.read(habitsProvider).length : widget.habit!.order,
    );

    ref.read(habitRepoProvider).saveHabit(updated).then((_) {
      if (!mounted) return;
      ref.read(refreshTriggerProvider.notifier).state++;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.scaffoldBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.habit == null ? 'Add Habit' : 'Edit Habit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Habit Name',
                hintText: 'e.g. Meditate 10 min',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Emoji', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMedium)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.white,
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<HabitType>(
              value: _type,
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: HabitType.checkbox, child: Text('Checkbox (Tick daily)')),
                DropdownMenuItem(value: HabitType.counter, child: Text('Counter (Step-by-step)')),
                DropdownMenuItem(value: HabitType.autoSteps, child: Text('Auto from Steps')),
                DropdownMenuItem(value: HabitType.autoSleep, child: Text('Auto from Sleep')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _type = val);
              },
            ),
            if (_type != HabitType.checkbox) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetCtrl,
                      decoration: InputDecoration(
                        labelText: 'Target',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _unitCtrl,
                      decoration: InputDecoration(
                        labelText: 'Unit (e.g. L)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_type == HabitType.counter) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _stepCtrl,
                decoration: InputDecoration(
                  labelText: 'Increment Step (e.g. 0.25)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
