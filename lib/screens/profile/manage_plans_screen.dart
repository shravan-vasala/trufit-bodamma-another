import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';

class ManagePlansScreen extends ConsumerWidget {
  const ManagePlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          title: const Text('Manage Plans'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMedium,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Workout Plans'),
              Tab(text: 'Meal Slots'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PlanEditor(
              type: 'workout',
              getKeys: () => ref.read(workoutRepoProvider).getPlanKeys(),
              getRawJson: (key) => ref.read(workoutRepoProvider).getRawPlanJson(key),
              saveJson: (key, json) =>
                  ref.read(workoutRepoProvider).savePlanJson(key, json),
            ),
            const _MealSlotsEditor(),
          ],
        ),
      ),
    );
  }
}

class _MealSlotsEditor extends ConsumerStatefulWidget {
  const _MealSlotsEditor();
  @override
  ConsumerState<_MealSlotsEditor> createState() => _MealSlotsEditorState();
}

class _MealSlotsEditorState extends ConsumerState<_MealSlotsEditor> {
  void _deleteSlot(Map<String, dynamic> slot) {
    final profile = ref.read(profileProvider);
    final updatedSlots = profile.customMealSlots.where((s) => s['id'] != slot['id']).toList();
    ref.read(profileRepoProvider).saveProfile(profile.copyWith(customMealSlots: updatedSlots));
  }

  void _editSlot(Map<String, dynamic> slot, int index) {
    final nameCtrl = TextEditingController(text: slot['name'] as String);
    String selectedEmoji = slot['emoji'] as String;
    final emojis = ['🍴', '🥤', '🍌', '🥜', '🍚', '🫖', '🍪', '🥩', '🥑', '🥪', '🥣', '🥗', '🍳', '🍛', '🍎', '🍽️'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Edit Meal Slot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              const Text('Emoji:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emojis.map((e) {
                  final isSelected = e == selectedEmoji;
                  return GestureDetector(
                    onTap: () => setStateDialog(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final profile = ref.read(profileProvider);
                final updatedSlots = List<Map<String, dynamic>>.from(profile.customMealSlots);
                updatedSlots[index] = {
                  ...slot,
                  'name': nameCtrl.text.trim(),
                  'emoji': selectedEmoji,
                };
                ref.read(profileRepoProvider).saveProfile(profile.copyWith(customMealSlots: updatedSlots));
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final slots = profile.customMealSlots;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isDefault = slot['isDefault'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text(slot['emoji'] as String, style: const TextStyle(fontSize: 24)),
            title: Text(slot['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isDefault ? 'Default Slot' : 'Custom Recurring Slot'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                  onPressed: () => _editSlot(slot, index),
                ),
                if (!isDefault)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Slot?'),
                          content: const Text('Removing this recurring slot means it will no longer appear on future days. Previously logged food will still be kept.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () {
                                _deleteSlot(slot);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Delete', style: TextStyle(color: AppColors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanEditor extends StatefulWidget {
  const _PlanEditor({
    required this.type,
    required this.getKeys,
    required this.getRawJson,
    required this.saveJson,
  });

  final String type;
  final List<String> Function() getKeys;
  final String? Function(String) getRawJson;
  final Future<void> Function(String, String) saveJson;

  @override
  State<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<_PlanEditor> {
  String? _selectedKey;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final keys = widget.getKeys();
    if (keys.isNotEmpty) {
      _selectedKey = keys.first;
      _loadJson();
    }
  }

  void _loadJson() {
    if (_selectedKey != null) {
      final json = widget.getRawJson(_selectedKey!);
      _controller.text = json ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.getKeys();

    if (keys.isEmpty) {
      return const Center(child: Text('No plans found'));
    }

    return Column(
      children: [
        // Plan selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedKey,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: keys.map((k) {
                      return DropdownMenuItem(
                        value: k,
                        child: Text(k, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedKey = v;
                        _loadJson();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        // JSON editor
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.textDark,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: 'Paste JSON here...',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_selectedKey == null) return;
    try {
      await widget.saveJson(_selectedKey!, _controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Plan saved successfully! ✅'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid JSON: $e'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
