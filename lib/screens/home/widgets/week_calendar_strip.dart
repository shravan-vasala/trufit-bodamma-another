import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../models/habit.dart';
import '../../../utils/workout_completion.dart';
import 'past_day_summary_sheet.dart';
import 'daily_score_sheet.dart';

class WeekCalendarStrip extends ConsumerStatefulWidget {
  const WeekCalendarStrip({super.key});

  @override
  ConsumerState<WeekCalendarStrip> createState() => _WeekCalendarStripState();
}

class _WeekCalendarStripState extends ConsumerState<WeekCalendarStrip> {
  late PageController _pageController;
  final int _basePage = 10000;

  @override
  void initState() {
    super.initState();
    // Use the initial week offset if any
    final initialOffset = ref.read(weekOffsetProvider);
    _pageController = PageController(initialPage: _basePage + initialOffset);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    ref.listen<int>(weekOffsetProvider, (prev, next) {
      if (_pageController.hasClients) {
        final targetPage = _basePage + next;
        if (_pageController.page?.round() != targetPage) {
          _pageController.animateToPage(
            targetPage,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.colors.textLight.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!_isSameDay(selectedDate, today)) ...[
                GestureDetector(
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).state = today;
                    ref.read(weekOffsetProvider.notifier).state = 0;
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
              ],
              Text(
                DateFormat('EEE, d').format(selectedDate),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textDark,
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM').format(selectedDate).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textLight,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy').format(selectedDate),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textLight,
                    ),
                  ),
                ],
              ),
              Spacer(),
              const _DailyScoreRing(),
              SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: context.colors.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    ref.read(selectedDateProvider.notifier).state = picked;
                    // Calculate week offset between today and picked date
                    final pickedWeekStart = picked.subtract(Duration(days: picked.weekday - 1));
                    final todayWeekStart = today.subtract(Duration(days: today.weekday - 1));
                    final diffDays = pickedWeekStart.difference(todayWeekStart).inDays;
                    final weekOffset = (diffDays / 7).round();
                    ref.read(weekOffsetProvider.notifier).state = weekOffset;
                  }
                },
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: context.colors.textLight,
                  size: 24,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Week day circles
          SizedBox(
            height: 70,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) {
                ref.read(weekOffsetProvider.notifier).state = idx - _basePage;
              },
              itemBuilder: (context, index) {
                final weekOffset = index - _basePage;
                final weekStart = today
                    .subtract(Duration(days: today.weekday - 1))
                    .add(Duration(days: weekOffset * 7));
                final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weekDays.map((day) {
                    return _DayCircle(
                      date: day,
                      isSelected: _isSameDay(day, selectedDate),
                      isToday: _isSameDay(day, today),
                      isFuture: day.isAfter(today),
                      ref: ref,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.ref,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('E').format(date).substring(0, 3);
    final dayNum = date.day.toString();

    // Check if there's activity on this day
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    // Watch to rebuild when activity is logged on the selected date
    ref.watch(dailyLogProvider);
    ref.watch(habitCompletionsProvider);
    final hasActivity = ref.read(dailyLogRepoProvider).hasActivityOnDate(dateStr);
    final mealLog = ref.read(mealRepoProvider).getDailyLog(dateStr);
    final habitCompletions = ref.read(habitRepoProvider).getCompletions(dateStr);
    
    final habits = ref.read(habitRepoProvider).getHabits();
    final applicableHabits = habits.where((h) {
      final habitDate = DateTime(h.createdAt.year, h.createdAt.month, h.createdAt.day);
      final sDate = DateTime(date.year, date.month, date.day);
      return !habitDate.isAfter(sDate);
    }).toList();
    
    final dailyLog = ref.read(dailyLogRepoProvider).getOrCreate(dateStr);
    final completedHabits = applicableHabits.where((h) => isHabitCompleted(h, habitCompletions, dailyLog)).length;
    
    final isComplete = hasActivity || mealLog.loggedSlotsCount > 0 || completedHabits > 0;

    // Planned rest: no activity dot — green/red would misread rest as success/failure.
    final plan = ref.read(workoutPlanProvider);
    final isRestDay = plan != null
        ? WorkoutCompletion.isRestDay(
            WorkoutCompletion.resolveWorkoutDay(plan, date),
            date,
          )
        : date.weekday == DateTime.sunday;

    final muted = context.colors.border;
    Color? dotColor;
    if (isRestDay) {
      dotColor = null;
    } else if (isFuture) {
      dotColor = muted;
    } else if (isToday) {
      dotColor = isComplete ? context.colors.green : context.colors.red;
    } else {
      dotColor = isComplete ? context.colors.green : muted;
    }

    return GestureDetector(
      onTap: () {
        if (isFuture || isToday) {
          ref.read(selectedDateProvider.notifier).state = date;
        } else {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => PastDaySummarySheet(date: date),
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? context.colors.primary : context.colors.textLight,
            ),
          ),
          SizedBox(height: 6),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? context.colors.primary : Colors.transparent,
            ),
            child: Center(
              child: Text(
                dayNum,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? context.colors.white
                      : (isToday ? context.colors.primary : context.colors.textDark),
                ),
              ),
            ),
          ),
          SizedBox(height: 6),
          // Activity dot (hidden on rest days)
          SizedBox(
            width: 5,
            height: 5,
            child: dotColor == null
                ? null
                : DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DailyScoreRing extends ConsumerWidget {
  const _DailyScoreRing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreData = ref.watch(dailyScoreProvider);

    Color scoreColor = context.colors.green;
    if (scoreData.totalScore < 50) {
      scoreColor = context.colors.red;
    } else if (scoreData.totalScore < 80) {
      scoreColor = context.colors.orange;
    }
    
    final displayScore = scoreData.isFutureDate ? '--' : scoreData.totalScore.toString();
    final progress = scoreData.isFutureDate ? 0.0 : scoreData.totalScore / 100.0;

    return GestureDetector(
      onTap: scoreData.isFutureDate ? null : () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const DailyScoreSheet(),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Daily Score',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textLight,
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CustomPaint(
                      size: const Size(36, 36),
                      painter: _ScoreRingPainter(
                        progress: value,
                        color: scoreColor,
                        trackColor: context.colors.border,
                      ),
                    );
                  },
                ),
                Text(
                  displayScore,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scoreData.isFutureDate ? context.colors.textLight : context.colors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 4.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -3.14159 / 2; // -90 degrees
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.trackColor != trackColor;
  }
}
