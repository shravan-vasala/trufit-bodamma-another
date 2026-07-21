import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/body_stats.dart';

class BodyStatsScreen extends ConsumerStatefulWidget {
  const BodyStatsScreen({super.key});

  @override
  ConsumerState<BodyStatsScreen> createState() => _BodyStatsScreenState();
}

class _BodyStatsScreenState extends ConsumerState<BodyStatsScreen> {
  final _controllers = <String, TextEditingController>{};
  bool _isEditing = false;

  final _fields = [
    'Waist',
    'Hips',
    'Chest',
    'Left Arm',
    'Right Arm',
    'Left Thigh',
    'Right Thigh',
    'Neck',
  ];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _controllers[f] = TextEditingController();
    }
    _loadData();
  }

  void _loadData() {
    final stats = ref.read(bodyStatsRepoProvider).getLatestStats();
    if (stats != null) {
      final m = stats.allMeasurements;
      for (final f in _fields) {
        if (m[f] != null) {
          _controllers[f]!.text = m[f]!.toStringAsFixed(1);
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Body Stats'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_isEditing) {
                _save();
              }
              setState(() => _isEditing = !_isEditing);
            },
            child: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.straighten_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Body Measurements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All measurements in cm',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._fields.map((field) => _buildField(field)),
        ],
      ),
    );
  }

  Widget _buildField(String field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              field,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: _isEditing
                ? TextField(
                    controller: _controllers[field],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      suffixText: 'cm',
                    ),
                  )
                : Text(
                    _controllers[field]!.text.isEmpty
                        ? '--'
                        : '${_controllers[field]!.text} cm',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _controllers[field]!.text.isEmpty
                          ? AppColors.textLight
                          : AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final stats = BodyStats(
      date: date,
      waist: double.tryParse(_controllers['Waist']!.text),
      hips: double.tryParse(_controllers['Hips']!.text),
      chest: double.tryParse(_controllers['Chest']!.text),
      leftArm: double.tryParse(_controllers['Left Arm']!.text),
      rightArm: double.tryParse(_controllers['Right Arm']!.text),
      leftThigh: double.tryParse(_controllers['Left Thigh']!.text),
      rightThigh: double.tryParse(_controllers['Right Thigh']!.text),
      neck: double.tryParse(_controllers['Neck']!.text),
    );
    ref.read(bodyStatsRepoProvider).saveStats(stats);
  }
}
