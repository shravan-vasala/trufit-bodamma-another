import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../models/habit.dart';
import 'past_day_summary_sheet.dart';

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
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textLight.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                DateFormat('EEE, d').format(selectedDate),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM').format(selectedDate).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const Spacer(),
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
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
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
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.textLight,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
    
    // Watch the refresh trigger to rebuild when activity is logged
    ref.watch(refreshTriggerProvider);
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
    
    Color dotColor;
    if (isFuture) {
      dotColor = const Color(0xFF1F2937); // black
    } else if (isToday) {
      dotColor = isComplete ? AppColors.green : const Color(0xFFEF4444); // green if done, else red
    } else {
      dotColor = isComplete ? AppColors.green : const Color(0xFF1F2937); // green if done, else black
    }

    return GestureDetector(
      onTap: () {
        if (isFuture || isToday) {
          ref.read(selectedDateProvider.notifier).state = date;
        } else {
          showModalBottomSheet(
            context: context,
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
              color: isSelected ? AppColors.primary : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
            child: Center(
              child: Text(
                dayNum,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.white
                      : (isToday ? AppColors.primary : AppColors.textDark),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Activity dot
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }
}
