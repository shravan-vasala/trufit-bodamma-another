import 'dart:math';
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
    required this.startDate,
    required this.endDate,
    this.isSteps = false,
    this.isCalories = false,
    this.showKgLbToggle = false,
    this.useKg = true,
    this.onToggleUnit,
    required this.statLabels,
    required this.statValues,
    this.timeFormat = ChartTimeFormat.monthly,
    this.emptyMessage = 'No data available for this period',
    this.targetValue,
    this.onPointLongPress,
  });

  final String title;
  final List<ChartDataPoint> data;
  final DateTime startDate;
  final DateTime endDate;
  final bool isSteps;
  final bool isCalories;
  final bool showKgLbToggle;
  final bool useKg;
  final VoidCallback? onToggleUnit;
  final List<String> statLabels;
  final List<String> statValues;
  final ChartTimeFormat timeFormat;
  final String emptyMessage;
  final double? targetValue;
  final void Function(DateTime date, double value)? onPointLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart Card
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
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
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textDark,
                    ),
                  ),
                  Spacer(),
                  if (showKgLbToggle)
                    GestureDetector(
                      onTap: onToggleUnit,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.lavender,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          useKg ? 'KG' : 'LB',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: data.isEmpty
                    ? Center(
                        child: Text(
                          emptyMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.colors.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _buildLineChart(context),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Stats Strip
        if (statLabels.isNotEmpty && statValues.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
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
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: context.colors.textLight,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              statValues[index],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.colors.textDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (index < statLabels.length - 1)
                        Container(
                          width: 1,
                          height: 30,
                          color: context.colors.border,
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

  Widget _buildLineChart(BuildContext context) {
    final spots = data.map((d) {
      final x = d.date.difference(startDate).inDays.toDouble();
      return FlSpot(x, d.value);
    }).toList();

    double minY = spots.map((s) => s.y).reduce(min);
    double maxY = spots.map((s) => s.y).reduce(max);
    
    if (minY == maxY) {
      if (minY == 0) {
        maxY = 10;
      } else {
        minY -= 1;
        maxY += 1;
      }
    } else {
      final padding = (maxY - minY) * 0.1;
      minY -= padding;
      maxY += padding;
    }
    
    final bool isCount = isSteps || isCalories;
    if (isCount && minY < 0) minY = 0;

    final maxXValue = endDate.difference(startDate).inDays.toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxXValue,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: context.colors.border,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final int daysOffset = value.toInt();
                if (daysOffset < 0 || daysOffset > maxXValue) {
                  return SizedBox.shrink();
                }

                final date = startDate.add(Duration(days: daysOffset));
                String label;

                if (timeFormat == ChartTimeFormat.weekly) {
                  label = DateFormat('E').format(date); // Mon, Tue...
                } else if (timeFormat == ChartTimeFormat.monthly) {
                  // Show roughly every 5 days without repeating
                  if (date.day == 1 || date.day % 5 == 0) {
                    label = date.day.toString();
                  } else {
                    return SizedBox.shrink();
                  }
                } else {
                  // sixMonths
                  if (date.day == 1) {
                    label = DateFormat('MMM').format(date);
                  } else {
                    return SizedBox.shrink();
                  }
                }

                return Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.colors.textLight,
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
                if (isCount && value < 0) return SizedBox.shrink();
                
                String label;
                if (isCount) {
                  if (value >= 1000) {
                    final kVal = value / 1000;
                    label = '${kVal.toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
                  } else {
                    label = value.toInt().toString();
                  }
                } else {
                  label = value.toStringAsFixed(1);
                }

                return Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.textLight,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
              if (event is FlLongPressEnd || event is FlLongPressMoveUpdate) {
                 if (event is FlLongPressEnd && onPointLongPress != null) {
                    final spot = response.lineBarSpots!.first;
                    final date = startDate.add(Duration(days: spot.x.toInt()));
                    onPointLongPress!(date, spot.y);
                 }
              }
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => context.colors.textDark,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = startDate.add(Duration(days: spot.x.toInt()));
                final dateStr = DateFormat('dd MMM yyyy').format(date);
                final valStr = spot.y.toStringAsFixed(isCount ? 0 : 1);
                return LineTooltipItem(
                  '$dateStr\n$valStr',
                  TextStyle(
                    color: context.colors.onPrimary,
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
            color: Color(0xFF8B5CF6),
            barWidth: 2.5,
            dotData: FlDotData(
              show: spots.length == 1,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: isCount
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xCCC4B5FD),
                        Color(0x00C4B5FD),
                      ],
                    ),
              color: isCount ? Color(0xCCC4B5FD) : null,
            ),
          ),
        ],
      ),
    );
  }
}
