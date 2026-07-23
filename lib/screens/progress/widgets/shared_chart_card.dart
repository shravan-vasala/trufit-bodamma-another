import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';

enum ChartTimeFormat { weekly, monthly, sixMonths, allTime }

class ChartDataPoint {
  final DateTime date;
  final double value;
  ChartDataPoint(this.date, this.value);
}

class SharedChartCard extends StatelessWidget {
  const SharedChartCard({
    super.key,
    required this.title,
    required this.data,
    this.isSteps = false,
    this.showKgLbToggle = false,
    this.useKg = true,
    this.onToggleUnit,
    required this.statLabels,
    required this.statValues,
    this.timeFormat = ChartTimeFormat.monthly,
    this.emptyMessage = 'No data available for this period',
  });

  final String title;
  final List<ChartDataPoint> data;
  final bool isSteps;
  final bool showKgLbToggle;
  final bool useKg;
  final VoidCallback? onToggleUnit;
  final List<String> statLabels;
  final List<String> statValues;
  final ChartTimeFormat timeFormat;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart Card
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
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  if (showKgLbToggle)
                    GestureDetector(
                      onTap: onToggleUnit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lavender,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          useKg ? 'KG' : 'LB',
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
                child: data.isEmpty
                    ? Center(
                        child: Text(
                          emptyMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      )
                    : _buildLineChart(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Stats Strip
        if (statLabels.isNotEmpty && statValues.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                statLabels.length,
                (index) => Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              statLabels[index],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textLight,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statValues[index],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < statLabels.length - 1)
                        Container(
                          width: 1,
                          height: 30,
                          color: AppColors.border,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLineChart() {
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    } else {
      final padding = (maxY - minY) * 0.1;
      minY -= padding;
      maxY += padding;
    }
    // Prevent negative steps or weight if not applicable
    if (minY < 0 && isSteps) minY = 0;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                
                // Thin out labels for longer datasets
                if (data.length > 14 && idx % (data.length ~/ 6) != 0) {
                  return const SizedBox.shrink();
                }

                String label;
                final date = data[idx].date;
                if (timeFormat == ChartTimeFormat.weekly) {
                  label = DateFormat('E').format(date); // Mon, Tue, etc.
                } else if (timeFormat == ChartTimeFormat.monthly) {
                  label = DateFormat('MMM dd').format(date); // Apr 14
                } else {
                  label = DateFormat('MMM yyyy').format(date); // Apr 2026
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
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
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Ensure 4-5 labels max
                return Text(
                  value.toStringAsFixed(isSteps ? 0 : 1),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.textDark,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                if (idx < 0 || idx >= data.length) return null;
                final dateStr = DateFormat('dd MMM yyyy').format(data[idx].date);
                final valStr = spot.y.toStringAsFixed(isSteps ? 0 : 1);
                return LineTooltipItem(
                  '$dateStr\n$valStr',
                  const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF8B5CF6),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: isSteps
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xCCC4B5FD),
                        Color(0x00C4B5FD),
                      ],
                    ),
              color: isSteps ? const Color(0xCCC4B5FD) : null,
            ),
          ),
        ],
      ),
    );
  }
}
