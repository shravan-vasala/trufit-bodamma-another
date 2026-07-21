import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/daily_log.dart';

enum MetricType { weight, steps, sleep, bmi, bodyFat }

enum TimeRange { weekly, monthly, sixMonths }

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  MetricType _selectedMetric = MetricType.weight;
  TimeRange _selectedRange = TimeRange.monthly;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _metricTitle(_selectedMetric),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const Spacer(),
                            if (_selectedMetric == MetricType.weight)
                              GestureDetector(
                                onTap: () {
                                  ref.read(profileProvider.notifier).toggleUnit();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.lavender,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    profile.useKg ? 'KG' : 'LB',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: _buildChart(logs, profile.useKg, profile),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats strip
                  _buildStatsStrip(logs, profile),
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
      }
    }).toList();

    if (filteredLogs.isEmpty) {
      return Center(
        child: Text(
          'No data for this period',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),
      );
    }

    final spots = filteredLogs.asMap().entries.map((e) {
      double value;
      switch (_selectedMetric) {
        case MetricType.weight:
          value = useKg ? e.value.weight! : e.value.weight! * 2.20462;
          break;
        case MetricType.steps:
          value = e.value.steps!.toDouble();
          break;
        case MetricType.sleep:
          value = e.value.sleepHours!;
          break;
        case MetricType.bmi:
          final h = profile.heightInMeters;
          value = e.value.weight! / (h * h);
          break;
        case MetricType.bodyFat:
          value = e.value.bodyFat!;
          break;
      }
      return FlSpot(e.key.toDouble(), value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= filteredLogs.length) {
                  return const SizedBox.shrink();
                }
                if (filteredLogs.length > 10 && idx % 3 != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('dd').format(DateTime.parse(filteredLogs[idx].date)),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textLight),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: spots.length <= 14,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.white,
                strokeWidth: 2,
                strokeColor: AppColors.primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsStrip(List<DailyLog> logs, dynamic profile) {
    List<_StatItem> stats = [];

    switch (_selectedMetric) {
      case MetricType.steps:
        final stepsLogs = logs.where((l) => l.steps != null).toList();
        if (stepsLogs.isNotEmpty) {
          final total = stepsLogs.fold<int>(0, (s, l) => s + l.steps!);
          final avg = total ~/ stepsLogs.length;
          final max = stepsLogs.map((l) => l.steps!).reduce((a, b) => a > b ? a : b);
          stats = [
            _StatItem('AVERAGE', avg.toString()),
            _StatItem('TOTAL', total.toString()),
            _StatItem('MAX', max.toString()),
          ];
        }
        break;
      case MetricType.weight:
        final weightLogs = logs.where((l) => l.weight != null).toList();
        if (weightLogs.isNotEmpty) {
          final useKg = profile.useKg as bool;
          final unit = useKg ? 'kg' : 'lb';
          final values = weightLogs
              .map((l) => useKg ? l.weight! : l.weight! * 2.20462)
              .toList();
          final avg = values.reduce((a, b) => a + b) / values.length;
          final max = values.reduce((a, b) => a > b ? a : b);
          final min = values.reduce((a, b) => a < b ? a : b);
          stats = [
            _StatItem('AVERAGE', '${avg.toStringAsFixed(1)} $unit'),
            _StatItem('MAX', '${max.toStringAsFixed(1)} $unit'),
            _StatItem('MIN', '${min.toStringAsFixed(1)} $unit'),
          ];
        }
        break;
      default:
        break;
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stats
            .map((s) => Column(
                  children: [
                    Text(
                      s.label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
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
    }
  }
}

class _StatItem {
  final String label;
  final String value;
  _StatItem(this.label, this.value);
}
