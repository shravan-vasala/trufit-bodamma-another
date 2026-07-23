import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';

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

    return Column(
      children: [
        // Date header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Today pill button
              GestureDetector(
                onTap: () {
                  ref.read(selectedDateProvider.notifier).state = today;
                  ref.read(weekOffsetProvider.notifier).state = 0;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('EEE, dd MMM yyyy').format(selectedDate).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
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
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Week day circles
        SizedBox(
          height: 75,
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

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: weekDays.map((day) {
                    return _DayCircle(
                      date: day,
                      isSelected: _isSameDay(day, selectedDate),
                      isToday: _isSameDay(day, today),
                      isFuture: day.isAfter(today),
                      ref: ref,
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
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
    final dayName = DateFormat('E').format(date).substring(0, 2);
    final dayNum = date.day.toString();

    // Check if there's activity on this day
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    // Watch the refresh trigger to rebuild when activity is logged
    ref.watch(refreshTriggerProvider);
    final hasActivity = ref.read(dailyLogRepoProvider).hasActivityOnDate(dateStr);

    return GestureDetector(
      onTap: () {
        ref.read(selectedDateProvider.notifier).state = date;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.primary
                  : (isToday
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (isFuture
                          ? AppColors.lavender
                          : Colors.transparent)),
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                dayNum,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.white
                      : (isToday ? AppColors.primary : AppColors.textDark),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Activity dot (every day gets a dot)
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasActivity ? AppColors.green : const Color(0xFFD1D5DB),
            ),
          ),
        ],
      ),
    );
  }
}
