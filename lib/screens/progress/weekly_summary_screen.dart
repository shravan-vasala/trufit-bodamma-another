import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../providers/weekly_summary_provider.dart';
import '../../providers/app_providers.dart';
import 'package:intl/intl.dart';

class WeeklySummaryScreen extends ConsumerWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(weeklySummaryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    
    // Get week bounds for title
    final weekday = selectedDate.weekday;
    final startOfWeek = selectedDate.subtract(Duration(days: weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final titleText = '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Weekly Summary'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                titleText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // ── Score Hero Card ──
              _ScoreHeroCard(score: summary.weekScore),
              const SizedBox(height: 24),
              
              // ── Habits Chart ──
              if (summary.habitCompletionRate > 0)
                _HabitChartCard(rates: summary.dailyHabitRates),
              if (summary.habitCompletionRate > 0)
                const SizedBox(height: 16),

              // ── Grid Stats ──
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1, // slightly wide cards
                children: [
                  _StatCard(
                    title: 'Workouts',
                    icon: Icons.fitness_center_rounded,
                    primaryValue: '${summary.workoutsCompleted}/${summary.workoutsTotal}',
                    subtitle: 'Sections Done',
                  ),
                  _StatCard(
                    title: 'Habits',
                    icon: Icons.checklist_rounded,
                    primaryValue: '${(summary.habitCompletionRate * 100).toInt()}%',
                    subtitle: summary.bestHabit != null ? 'Best: ${summary.bestHabit}' : 'Completion',
                  ),
                  _StatCard(
                    title: 'Steps',
                    icon: Icons.directions_walk_rounded,
                    primaryValue: '${summary.avgSteps}',
                    subtitle: 'Avg / day (Best: ${summary.bestSteps})',
                  ),
                  _StatCard(
                    title: 'Sleep',
                    icon: Icons.nightlight_round,
                    primaryValue: '${summary.avgSleep.toStringAsFixed(1)}h',
                    subtitle: 'Avg / night',
                    tertiaryText: summary.nightsUnder7h > 0 ? '${summary.nightsUnder7h} nights < 7h' : null,
                  ),
                  _StatCard(
                    title: 'Nutrition',
                    icon: Icons.local_fire_department_rounded,
                    primaryValue: '${summary.avgCalories}',
                    subtitle: 'Avg kcal / day',
                    tertiaryText: '${summary.daysOverCalories} days over limit',
                  ),
                  _StatCard(
                    title: 'Weight',
                    icon: Icons.monitor_weight_rounded,
                    primaryValue: summary.weightDelta != 0 
                      ? (summary.weightDelta > 0 ? '+${summary.weightDelta.toStringAsFixed(1)}' : summary.weightDelta.toStringAsFixed(1))
                      : '-',
                    subtitle: 'Delta this week',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // ── Share Button ──
              ElevatedButton.icon(
                onPressed: () {
                  final text = summary.generateShareText();
                  Share.share(text);
                },
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share Summary'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreHeroCard extends StatelessWidget {
  final int score;
  const _ScoreHeroCard({required this.score});

  @override
  Widget build(BuildContext context) {
    String message;
    if (score >= 90) message = 'Crushing it! 🔥';
    else if (score >= 70) message = 'Great week! 👏';
    else if (score >= 50) message = 'Good effort! 👍';
    else message = 'Room to grow 🌱';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Week Score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitChartCard extends StatelessWidget {
  final List<double> rates;
  const _HabitChartCard({required this.rates});

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Daily Habits',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i > 6) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[i],
                            style: const TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: rates[i],
                        color: AppColors.primary,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 1.0,
                          color: AppColors.lavender,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String primaryValue;
  final String subtitle;
  final String? tertiaryText;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.primaryValue,
    required this.subtitle,
    this.tertiaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            primaryValue,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (tertiaryText != null) ...[
            const SizedBox(height: 2),
            Text(
              tertiaryText!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.red,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]
        ],
      ),
    );
  }
}
