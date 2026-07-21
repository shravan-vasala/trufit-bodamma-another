import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/exercise_log.dart';

class ExerciseProgressScreen extends ConsumerWidget {
  const ExerciseProgressScreen({super.key, required this.exerciseName});

  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(exerciseHistoryProvider(exerciseName));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(exerciseName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: 64,
                    color: AppColors.textLight.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No data logged yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Log exercise data to see your progress',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // Max weight chart
                _buildChartCard(
                  context,
                  title: 'Max Weight (kg)',
                  logs: logs,
                  getValue: (log) => log.maxWeight,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                // Total volume chart
                _buildChartCard(
                  context,
                  title: 'Total Volume (kg)',
                  logs: logs,
                  getValue: (log) => log.totalVolume,
                  color: AppColors.indigo,
                ),
                const SizedBox(height: 20),
                // History list
                const Text(
                  'HISTORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                ...logs.reversed.map((log) => _HistoryCard(log: log)),
              ],
            ),
    );
  }

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required List<ExerciseLog> logs,
    required double Function(ExerciseLog) getValue,
    required Color color,
  }) {
    final spots = logs.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), getValue(e.value));
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
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
                        if (idx < 0 || idx >= logs.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('dd/MM').format(
                                DateTime.parse(logs[idx].date)),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textLight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.white,
                        strokeWidth: 2,
                        strokeColor: color,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.log});

  final ExerciseLog log;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(log.date));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.sets.map((s) => '${s.reps}×${s.weight}kg').join(' | '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${log.totalVolume.toStringAsFixed(0)} kg',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'volume',
                style: TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
