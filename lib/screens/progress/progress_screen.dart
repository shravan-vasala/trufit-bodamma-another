import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/daily_log.dart';
import 'widgets/shared_chart_card.dart';

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
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric ?? MetricType.weight;
    _endDate = DateTime.now();
  }

  DateTime get _startDate {
    switch (_selectedRange) {
      case TimeRange.weekly:
        return _endDate.subtract(const Duration(days: 7));
      case TimeRange.monthly:
        return DateTime(_endDate.year, _endDate.month - 1, _endDate.day);
      case TimeRange.sixMonths:
        return DateTime(_endDate.year, _endDate.month - 6, _endDate.day);
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
                      onTap: () => setState(() => _selectedRange = range),
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
                  onPressed: () {
                    setState(() {
                      _endDate = _endDate.subtract(
                          Duration(days: _selectedRange == TimeRange.weekly ? 7 : 30));
                    });
                  },
                ),
                Text(
                  '${DateFormat('MMM yyyy').format(_startDate)} - ${DateFormat('MMM yyyy').format(_endDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      _endDate = _endDate.add(
                          Duration(days: _selectedRange == TimeRange.weekly ? 7 : 30));
                    });
                  },
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
                  const SizedBox(height: 24),
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
    final filteredLogs = logs.where((l) {
      switch (_selectedMetric) {
        case MetricType.weight:
          return l.weight != null;
        case MetricType.steps:
          return l.steps != null;
        case MetricType.sleep:
          return l.sleepHours != null;
        case MetricType.bmi:
          return l.weight != null;
        case MetricType.bodyFat:
          return l.bodyFat != null;
        case MetricType.calories:
          return false;
      }
    }).toList();

    // Fill in gaps depending on the range
    final List<ChartDataPoint> data = [];
    if (filteredLogs.isNotEmpty) {
      final startDate = DateTime.parse(filteredLogs.first.date);
      final endDate = DateTime.parse(filteredLogs.last.date);
      
      final daysDiff = endDate.difference(startDate).inDays;
      final logsByDate = {for (var l in filteredLogs) l.date: l};
      
      for (int i = 0; i <= daysDiff; i++) {
        final d = startDate.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(d);
        final log = logsByDate[dateStr];
        
        if (log != null) {
          double val = 0;
          switch (_selectedMetric) {
            case MetricType.weight:
              val = useKg ? log.weight! : log.weight! * 2.20462;
              break;
            case MetricType.steps:
              val = log.steps!.toDouble();
              break;
            case MetricType.sleep:
              val = log.sleepHours!;
              break;
            case MetricType.bmi:
              final h = profile.heightInMeters;
              val = log.weight! / (h * h);
              break;
            case MetricType.bodyFat:
              val = log.bodyFat!;
              break;
            case MetricType.calories:
              val = 0;
              break;
          }
          data.add(ChartDataPoint(d, val));
        } else {
          if (_selectedMetric == MetricType.steps) {
            data.add(ChartDataPoint(d, 0)); // Missing steps means 0
          } else {
            // For others, if we want to connect smoothly we can just omit missing days from data.
            // fl_chart connects the adjacent points if we just don't add the gap point.
            // Except for 6-months we might need to do real downsampling, but keeping it simple connects the dots.
          }
        }
      }
    }

    // Determine stats
    List<String> labels = [];
    List<String> values = [];
    
    if (filteredLogs.isNotEmpty) {
      if (_selectedMetric == MetricType.steps) {
        final steps = filteredLogs.map((l) => l.steps!).toList();
        final total = steps.reduce((a, b) => a + b);
        final avg = total ~/ steps.length;
        final max = steps.reduce((a, b) => a > b ? a : b);
        labels = ['AVERAGE', 'TOTAL', 'MAX'];
        values = [avg.toString(), total.toString(), max.toString()];
      } else if (_selectedMetric == MetricType.weight) {
        final weights = filteredLogs.map((l) => useKg ? l.weight! : l.weight! * 2.20462).toList();
        final avg = weights.reduce((a, b) => a + b) / weights.length;
        final max = weights.reduce((a, b) => a > b ? a : b);
        final min = weights.reduce((a, b) => a < b ? a : b);
        final unit = useKg ? 'kg' : 'lb';
        labels = ['AVERAGE', 'MAX', 'MIN'];
        values = ['${avg.toStringAsFixed(1)} $unit', '${max.toStringAsFixed(1)} $unit', '${min.toStringAsFixed(1)} $unit'];
      } else if (_selectedMetric == MetricType.sleep) {
        final sleeps = filteredLogs.map((l) => l.sleepHours!).toList();
        final avg = sleeps.reduce((a, b) => a + b) / sleeps.length;
        final max = sleeps.reduce((a, b) => a > b ? a : b);
        final min = sleeps.reduce((a, b) => a < b ? a : b);
        labels = ['AVERAGE', 'MAX', 'MIN'];
        values = ['${avg.toStringAsFixed(1)}h', '${max.toStringAsFixed(1)}h', '${min.toStringAsFixed(1)}h'];
      } else if (_selectedMetric == MetricType.bmi) {
        final h = profile.heightInMeters;
        final bmis = filteredLogs.map((l) => l.weight! / (h * h)).toList();
        final avg = bmis.reduce((a, b) => a + b) / bmis.length;
        final max = bmis.reduce((a, b) => a > b ? a : b);
        final min = bmis.reduce((a, b) => a < b ? a : b);
        labels = ['AVERAGE', 'MAX', 'MIN'];
        values = [avg.toStringAsFixed(1), max.toStringAsFixed(1), min.toStringAsFixed(1)];
      } else if (_selectedMetric == MetricType.bodyFat) {
        final fats = filteredLogs.map((l) => l.bodyFat!).toList();
        final avg = fats.reduce((a, b) => a + b) / fats.length;
        final max = fats.reduce((a, b) => a > b ? a : b);
        final min = fats.reduce((a, b) => a < b ? a : b);
        labels = ['AVERAGE', 'MAX', 'MIN'];
        values = ['${avg.toStringAsFixed(1)}%', '${max.toStringAsFixed(1)}%', '${min.toStringAsFixed(1)}%'];
      }
    }

    ChartTimeFormat format;
    switch (_selectedRange) {
      case TimeRange.weekly: format = ChartTimeFormat.weekly; break;
      case TimeRange.monthly: format = ChartTimeFormat.monthly; break;
      case TimeRange.sixMonths: format = ChartTimeFormat.sixMonths; break;
    }

    return SharedChartCard(
      title: _metricTitle(_selectedMetric),
      data: data,
      isSteps: _selectedMetric == MetricType.steps,
      showKgLbToggle: _selectedMetric == MetricType.weight,
      useKg: useKg,
      onToggleUnit: () => ref.read(profileProvider.notifier).toggleUnit(),
      statLabels: labels,
      statValues: values,
      timeFormat: format,
      emptyMessage: 'No ${_metricLabel(_selectedMetric).toLowerCase()} entries yet — tap + to log',
    );
  }

  Widget _buildCaloriesChart(String startStr, String endStr, dynamic profile) {
    final mealLogs = ref.watch(dailyMealLogsRangeProvider((startStr, endStr)));
    
    final List<ChartDataPoint> data = [];
    final List<int> validCalories = [];
    
    for (final log in mealLogs) {
      final d = DateTime.parse(log.date);
      data.add(ChartDataPoint(d, log.totalCalories.toDouble()));
      if (log.totalCalories > 0) {
        validCalories.add(log.totalCalories);
      }
    }
    
    List<String> labels = ['AVERAGE', 'MAX', 'MIN'];
    List<String> values = ['0', '0', '0'];
    
    if (validCalories.isNotEmpty) {
      final sum = validCalories.reduce((a, b) => a + b);
      final avg = sum ~/ validCalories.length;
      final max = validCalories.reduce((a, b) => a > b ? a : b);
      final min = validCalories.reduce((a, b) => a < b ? a : b);
      values = [avg.toString(), max.toString(), min.toString()];
    }

    ChartTimeFormat format;
    switch (_selectedRange) {
      case TimeRange.weekly: format = ChartTimeFormat.weekly; break;
      case TimeRange.monthly: format = ChartTimeFormat.monthly; break;
      case TimeRange.sixMonths: format = ChartTimeFormat.sixMonths; break;
    }

    return SharedChartCard(
      title: 'Calories',
      data: data,
      isSteps: false,
      showKgLbToggle: false,
      useKg: true,
      onToggleUnit: () {},
      statLabels: labels,
      statValues: values,
      timeFormat: format,
      emptyMessage: 'No calories logged yet',
      targetValue: profile.targetCalories.toDouble(),
    );
  }

  String _rangeLabel(TimeRange range) {
    switch (range) {
      case TimeRange.weekly:
        return 'Weekly';
      case TimeRange.monthly:
        return 'Monthly';
      case TimeRange.sixMonths:
        return '6 Months';
    }
  }

  String _metricTitle(MetricType metric) {
    switch (metric) {
      case MetricType.weight:
        return 'Body Weight';
      case MetricType.steps:
        return 'Steps';
      case MetricType.sleep:
        return 'Sleep';
      case MetricType.bmi:
        return 'BMI';
      case MetricType.bodyFat:
        return 'Body Fat';
      case MetricType.calories:
        return 'Calories';
    }
  }

  String _metricLabel(MetricType metric) {
    switch (metric) {
      case MetricType.weight:
        return 'Weight';
      case MetricType.steps:
        return 'Steps';
      case MetricType.sleep:
        return 'Sleep';
      case MetricType.bmi:
        return 'BMI';
      case MetricType.bodyFat:
        return 'Body Fat';
      case MetricType.calories:
        return 'Calories';
    }
  }

  IconData _metricIcon(MetricType metric) {
    switch (metric) {
      case MetricType.weight:
        return Icons.monitor_weight_rounded;
      case MetricType.steps:
        return Icons.directions_walk_rounded;
      case MetricType.sleep:
        return Icons.bedtime_rounded;
      case MetricType.bmi:
        return Icons.speed_rounded;
      case MetricType.bodyFat:
        return Icons.water_drop_rounded;
      case MetricType.calories:
        return Icons.restaurant_rounded;
    }
  }
}

