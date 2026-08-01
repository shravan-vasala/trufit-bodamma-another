import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/workout_plan.dart';
import '../../models/exercise_log.dart';
import '../../utils/pr_calculator.dart';
import '../../models/exercise_pr.dart';

class LogDataDialog extends ConsumerStatefulWidget {
  const LogDataDialog({super.key, required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<LogDataDialog> createState() => _LogDataDialogState();
}

class _LogDataDialogState extends ConsumerState<LogDataDialog> {
  late List<TextEditingController> _repsControllers;
  late List<TextEditingController> _weightControllers;
  ExerciseLog? _lastLog;
  ExercisePr? _currentPr;

  String _parseRepTarget(String rep) {
    if (rep.contains('-')) {
      final parts = rep.split('-');
      if (parts.length == 2) {
        return parts[1].trim();
      }
    }
    return rep;
  }

  @override
  void initState() {
    super.initState();
    final setCount = widget.exercise.setCount;
    _repsControllers = List.generate(setCount, (i) {
      return TextEditingController(text: _parseRepTarget(widget.exercise.reps[i]));
    });
    _weightControllers = List.generate(setCount, (i) {
      return TextEditingController(text: widget.exercise.weightKg?.toString() ?? '');
    });

    // Load existing data if any
    _loadExistingData();
  }

  void _loadExistingData() {
    final dateStr = ref.read(dateStringProvider);
    final repo = ref.read(exerciseLogRepoProvider);
    final existing = repo.getLog(dateStr, widget.exercise.name);
    _currentPr = repo.getPr(widget.exercise.name);
    
    if (existing != null) {
      for (int i = 0; i < existing.sets.length && i < _repsControllers.length; i++) {
        _repsControllers[i].text = existing.sets[i].reps.toString();
        _weightControllers[i].text =
            existing.sets[i].weight > 0 ? existing.sets[i].weight.toString() : '';
      }
    } else {
      // Find the most recent log to use as ghost text
      final allLogs = repo.getLogsForExercise(widget.exercise.name);
      if (allLogs.isNotEmpty) {
        _lastLog = allLogs.last; // Since it's sorted by date
      }
    }
  }

  @override
  void dispose() {
    for (final c in _repsControllers) {
      c.dispose();
    }
    for (final c in _weightControllers) {
      c.dispose();
    }
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
            Text(
              'Log: ${widget.exercise.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.exercise.setCount} set${widget.exercise.setCount > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 20),
            // Header row
            const Row(
              children: [
                SizedBox(width: 40),
                Expanded(
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'WEIGHT (kg)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(widget.exercise.setCount, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        'Set ${i + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _repsControllers[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weightControllers[i],
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: _lastLog != null && i < _lastLog!.sets.length 
                            ? _lastLog!.sets[i].weight.toString() 
                            : '0',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Log'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _save() {
    final dateStr = ref.read(dateStringProvider);
    final sets = <SetLog>[];
    for (int i = 0; i < widget.exercise.setCount; i++) {
      final reps = int.tryParse(_repsControllers[i].text) ?? 0;
      final weight = double.tryParse(_weightControllers[i].text) ?? 0;
      sets.add(SetLog(setNumber: i + 1, reps: reps, weight: weight));
    }

    final log = ExerciseLog(
      date: dateStr,
      exerciseName: widget.exercise.name,
      sets: sets,
    );
    final repo = ref.read(exerciseLogRepoProvider);
    repo.saveLog(log);
    
    // Check for PRs
    final prResult = PrCalculator.calculateNewPr(log, _currentPr);
    if (prResult.hasAnyNewPr) {
      repo.savePr(prResult.newPr);
    }
    
    Navigator.of(context).pop();

    String msg = 'Logged ${widget.exercise.name}';
    if (prResult.hasAnyNewPr) {
      if (prResult.isNewMaxWeight) {
        msg = 'New PR! ${prResult.newPr.maxWeight}kg';
      } else if (prResult.isNewMaxReps) {
        msg = 'New PR! ${prResult.newPr.maxReps} reps';
      } else if (prResult.isNewMaxVolume) {
        msg = 'New Volume PR!';
      } else if (prResult.isNew1RM) {
        msg = 'New 1RM PR!';
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: prResult.hasAnyNewPr ? AppColors.green : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
