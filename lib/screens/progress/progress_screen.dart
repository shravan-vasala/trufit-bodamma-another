import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/daily_log.dart';
import 'widgets/shared_chart_card.dart';
import '../home/weight_entry_dialog.dart';
import '../home/steps_entry_dialog.dart';

enum MetricType { weight, steps, sleep, bmi, bodyFat, calories }
enum TimeRange { weekly, monthly, sixMonths }

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key, this.initialMetric});
  
  final MetricType? initialMetric;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  late MetricType _selectedMetric;
  TimeRange _selectedRange = TimeRange.monthly;
  late DateTime _currentReferenceDate;

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric ?? MetricType.weight;
    _currentReferenceDate = DateTime.now();
  }

  DateTime get _startDate {
    final d = _currentReferenceDate;
    switch (_selectedRange) {
      case TimeRange.weekly:
        final daysToSubtract = d.weekday - DateTime.monday;
        return DateTime(d.year, d.month, d.day - daysToSubtract);
      case TimeRange.monthly:
        return DateTime(d.year, d.month, 1);
      case TimeRange.sixMonths:
        return DateTime(d.year, d.month - 5, 1);
    }
  }

  DateTime get _endDate {
    final d = _currentReferenceDate;
    switch (_selectedRange) {
      case TimeRange.weekly:
        return _startDate.add(const Duration(days: 6));
      case TimeRange.monthly:
        return DateTime(d.year, d.month + 1, 0);
      case TimeRange.sixMonths:
        return DateTime(d.year, d.month + 1, 0);
    }
  }

  void _shiftDate(int direction) {
    setState(() {
      if (_selectedRange == TimeRange.weekly) {
        _currentReferenceDate = _currentReferenceDate.add(Duration(days: 7 * direction));
      } else if (_selectedRange == TimeRange.monthly) {
        _currentReferenceDate = DateTime(_currentReferenceDate.year, _currentReferenceDate.month + direction, 1);
      } else {
        _currentReferenceDate = DateTime(_currentReferenceDate.year, _currentReferenceDate.month + (6 * direction), 1);
      }
    });
  }

  String get _headerText {
    if (_selectedRange == TimeRange.weekly) {
      return '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}';
    } else if (_selectedRange == TimeRange.monthly) {
      return DateFormat('MMM yyyy').format(_startDate);
    } else {
      return '${DateFormat('MMM yyyy').format(_startDate)} - ${DateFormat('MMM yyyy').format(_endDate)}';
    }
  }

  Future<void> _handlePointLongPress(DateTime date, double value) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text('Are you sure you want to delete the ${_metricLabel(_selectedMetric)} entry for ${DateFormat('MMM dd').format(date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(dailyLogRepoProvider);
      final log = repo.getLog(dateStr);
      if (log != null) {
        final newLog = DailyLog(
          date: log.date,
          weight: _selectedMetric == MetricType.weight ? null : log.weight,
          steps: _selectedMetric == MetricType.steps ? null : log.steps,
          stepsSource: _selectedMetric == MetricType.steps ? null : log.stepsSource,
          sleepHours: _selectedMetric == MetricType.sleep ? null : log.sleepHours,
          bodyFat: _selectedMetric == MetricType.bodyFat ? null : log.bodyFat,
          workoutCompleted: log.workoutCompleted,
          workoutDayId: log.workoutDayId,
        );
        await repo.saveLog(newLog);
        ref.read(refreshTriggerProvider.notifier).state++;
      }
    }
  }

  void _openManualEntry() {
    if (_selectedMetric == MetricType.weight || _selectedMetric == MetricType.bodyFat || _selectedMetric == MetricType.bmi) {
      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const WeightEntryDialog());
    } else if (_selectedMetric == MetricType.steps) {
      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const StepsEntryDialog());
    } else {
      // Generic simple dialog for Sleep or Calories if not fully supported elsewhere
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Manual entry for ${_metricLabel(_selectedMetric)} coming soon.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
    final logs = ref.watch(dailyLogsRangeProvider((startStr, endStr)));
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('My Progress'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: _selectedMetric != MetricType.bmi
          ? FloatingActionButton(
              onPressed: _openManualEntry,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: AppColors.white),
            )
          : null,
      body: Column(
        children: [
          // Time range segmented control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: TimeRange.values.map((range) {
                  final isSelected = _selectedRange == range;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedRange = range;
                        _currentReferenceDate = DateTime.now(); // reset to current date when swapping range
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _rangeLabel(range),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date range navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: AppColors.primary),
                  onPressed: () => _shiftDate(-1),
                ),
                Text(
                  _headerText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.primary),
                  onPressed: () => _shiftDate(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Chart card
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _selectedMetric == MetricType.calories
                    ? _buildCaloriesChart(startStr, endStr, profile)
                    : _buildChart(logs, profile.useKg, profile),
                  const SizedBox(height: 80), // Fab spacing
                ],
              ),
            ),
          ),

          // Metric tab bar
          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: MetricType.values.map((metric) {
                  final isSelected = _selectedMetric == metric;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMetric = metric),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _metricIcon(metric),
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textLight,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _metricLabel(metric),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 20,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<DailyLog> logs, bool useKg, dynamic profile) {
    final List<ChartDataPoint> data = [];
    final daysDiff = _endDate.difference(_startDate).inDays;
    final logsByDate = {for (var l in logs) l.date: l};
    
    int daysWithData = 0;

    for (int i = 0; i <= daysDiff; i++) {
      final d = _startDate.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      final log = logsByDate[dateStr];
      
      if (log != null) {
        double? val;
        switch (_selectedMetric) {
          case MetricType.weight:
            val = log.weight != null ? (useKg ? log.weight! : log.weight! * 2.20462) : null;
            break;
          case MetricType.steps:
            val = log.steps?.toDouble();
            break;
          case MetricType.sleep:
            val = log.sleepHours;
            break;
          case MetricType.bmi:
            if (log.weight != null) {
              final h = profile.heightInMeters;
              val = log.weight! / (h * h);
            }
            break;
          case MetricType.bodyFat:
            val = log.bodyFat;
            break;
          case MetricType.calories:
            val = null;
            break;
        }
        
        if (val != null) {
          data.add(ChartDataPoint(d, val));
          daysWithData++;
        } else {
          if (_selectedMetric == MetricType.steps) {
            data.add(ChartDataPoint(d, 0));
          }
        }
      } else {
        if (_selectedMetric == MetricType.steps) {
          data.add(ChartDataPoint(d, 0));
        }
      }
    }

    List<String> labels = [];
    List<String> values = [];
    
    if (daysWithData > 0) {
      final validData = data.where((d) => d.value > 0 || _selectedMetric != MetricType.steps).toList();
      
      if (_selectedMetric == MetricType.steps) {
        // Exclude 0 step days from average calculation
        final validSteps = validData.where((d) => d.value > 0).map((d) => d.value).toList();
        if (validSteps.isNotEmpty) {
          final total = validSteps.reduce((a, b) => a + b);
          final avg = total ~/ validSteps.length;
          final maxVal = validSteps.reduce((a, b) => a > b ? a : b);
          labels = ['AVERAGE\n(${validSteps.length} days)', 'TOTAL', 'MAX'];
          values = [avg.toString(), total.toInt().toString(), maxVal.toInt().toString()];
        }
      } else {
        final vals = validData.map((d) => d.value).toList();
        final avg = vals.reduce((a, b) => a + b) / vals.length;
        final maxVal = vals.reduce((a, b) => a > b ? a : b);
        final minVal = vals.reduce((a, b) => a < b ? a : b);
        
        if (_selectedMetric == MetricType.weight) {
          final unit = useKg ? 'kg' : 'lb';
          labels = ['AVERAGE\n(${vals.length} days)', 'MAX', 'MIN'];
          values = ['${avg.toStringAsFixed(1)} $unit', '${maxVal.toStringAsFixed(1)} $unit', '${minVal.toStringAsFixed(1)} $unit'];
        } else if (_selectedMetric == MetricType.sleep) {
          labels = ['AVERAGE\n(${vals.length} days)', 'MAX', 'MIN'];
          values = ['${avg.toStringAsFixed(1)}h', '${maxVal.toStringAsFixed(1)}h', '${minVal.toStringAsFixed(1)}h'];
        } else if (_selectedMetric == MetricType.bmi) {
          labels = ['AVERAGE\n(${vals.length} days)', 'MAX', 'MIN'];
          values = [avg.toStringAsFixed(1), maxVal.toStringAsFixed(1), minVal.toStringAsFixed(1)];
        } else if (_selectedMetric == MetricType.bodyFat) {
          labels = ['AVERAGE\n(${vals.length} days)', 'MAX', 'MIN'];
          values = ['${avg.toStringAsFixed(1)}%', '${maxVal.toStringAsFixed(1)}%', '${minVal.toStringAsFixed(1)}%'];
        }
      }
    }

    ChartTimeFormat format;
    switch (_selectedRange) {
      case TimeRange.weekly: format = ChartTimeFormat.weekly; break;
      case TimeRange.monthly: format = ChartTimeFormat.monthly; break;
      case TimeRange.sixMonths: format = ChartTimeFormat.sixMonths; break;
    }

    // Empty state logic: if no true valid data exists, we hide the chart
    final isEmpty = daysWithData == 0;
    String emptyMessage = 'No ${_metricLabel(_selectedMetric).toLowerCase()} entries yet.';
    if (_selectedMetric == MetricType.bmi) {
      emptyMessage = 'Log your weight to see BMI.';
    }

    return SharedChartCard(
      title: _metricTitle(_selectedMetric),
      data: isEmpty ? [] : data,
      startDate: _startDate,
      endDate: _endDate,
      isSteps: _selectedMetric == MetricType.steps,
      showKgLbToggle: _selectedMetric == MetricType.weight,
      useKg: useKg,
      onToggleUnit: () => ref.read(profileProvider.notifier).toggleUnit(),
      statLabels: isEmpty ? [] : labels,
      statValues: isEmpty ? [] : values,
      timeFormat: format,
      emptyMessage: emptyMessage,
      onPointLongPress: _handlePointLongPress,
    );
  }

  Widget _buildCaloriesChart(String startStr, String endStr, dynamic profile) {
    final mealLogs = ref.watch(dailyMealLogsRangeProvider((startStr, endStr)));
    final List<ChartDataPoint> data = [];
    final logsByDate = {for (var l in mealLogs) l.date: l};
    final daysDiff = _endDate.difference(_startDate).inDays;
    
    final validCalories = <int>[];

    for (int i = 0; i <= daysDiff; i++) {
      final d = _startDate.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      final log = logsByDate[dateStr];
      
      if (log != null && log.totalCalories > 0) {
        data.add(ChartDataPoint(d, log.totalCalories.toDouble()));
        validCalories.add(log.totalCalories);
      } else {
        data.add(ChartDataPoint(d, 0));
      }
    }
    
    List<String> labels = [];
    List<String> values = [];
    
    if (validCalories.isNotEmpty) {
      final sum = validCalories.reduce((a, b) => a + b);
      final avg = sum ~/ validCalories.length;
      final maxVal = validCalories.reduce((a, b) => a > b ? a : b);
      final minVal = validCalories.reduce((a, b) => a < b ? a : b);
      labels = ['AVERAGE\n(${validCalories.length} days)', 'MAX', 'MIN'];
      values = [avg.toString(), maxVal.toString(), minVal.toString()];
    }

    ChartTimeFormat format;
    switch (_selectedRange) {
      case TimeRange.weekly: format = ChartTimeFormat.weekly; break;
      case TimeRange.monthly: format = ChartTimeFormat.monthly; break;
      case TimeRange.sixMonths: format = ChartTimeFormat.sixMonths; break;
    }

    final isEmpty = validCalories.isEmpty;

    return SharedChartCard(
      title: 'Calories',
      data: isEmpty ? [] : data,
      startDate: _startDate,
      endDate: _endDate,
      isSteps: false,
      isCalories: true,
      showKgLbToggle: false,
      useKg: true,
      onToggleUnit: () {},
      statLabels: isEmpty ? [] : labels,
      statValues: isEmpty ? [] : values,
      timeFormat: format,
      emptyMessage: 'No calories logged yet.',
      targetValue: profile.targetCalories.toDouble(),
      onPointLongPress: null, // Deletion for calories should be via Meal UI
    );
  }

  String _rangeLabel(TimeRange range) {
    switch (range) {
      case TimeRange.weekly: return 'Weekly';
      case TimeRange.monthly: return 'Monthly';
      case TimeRange.sixMonths: return '6 Months';
    }
  }

  String _metricTitle(MetricType metric) {
    switch (metric) {
      case MetricType.weight: return 'Body Weight';
      case MetricType.steps: return 'Steps';
      case MetricType.sleep: return 'Sleep';
      case MetricType.bmi: return 'BMI';
      case MetricType.bodyFat: return 'Body Fat';
      case MetricType.calories: return 'Calories';
    }
  }

  String _metricLabel(MetricType metric) {
    switch (metric) {
      case MetricType.weight: return 'Weight';
      case MetricType.steps: return 'Steps';
      case MetricType.sleep: return 'Sleep';
      case MetricType.bmi: return 'BMI';
      case MetricType.bodyFat: return 'Body Fat';
      case MetricType.calories: return 'Calories';
    }
  }

  IconData _metricIcon(MetricType metric) {
    switch (metric) {
      case MetricType.weight: return Icons.monitor_weight_rounded;
      case MetricType.steps: return Icons.directions_walk_rounded;
      case MetricType.sleep: return Icons.bedtime_rounded;
      case MetricType.bmi: return Icons.speed_rounded;
      case MetricType.bodyFat: return Icons.water_drop_rounded;
      case MetricType.calories: return Icons.restaurant_rounded;
    }
  }
}
