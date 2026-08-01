import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/habit.dart';
import '../profile/manage_habits_screen.dart';
import 'widgets/week_calendar_strip.dart';
import 'widgets/meals_card.dart';
import 'widgets/habits_card.dart';
import 'widgets/daily_progress_grid.dart';
import 'widgets/coach_notes_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial sync when screen first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSteps(isManualRefresh: true);
      final profile = ref.read(profileProvider);
      if (profile.name.isEmpty) {
        _showNamePrompt();
      }
    });
  }

  void _showNamePrompt() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.white,
        title: Text("What's your name?", style: TextStyle(color: context.colors.textDark)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: context.colors.textDark),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: context.colors.textLight),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final profile = ref.read(profileProvider);
                ref.read(profileProvider.notifier).updateProfile(profile.copyWith(name: name));
                Navigator.of(context).pop();
              }
            },
            child: Text('Save', style: TextStyle(color: context.colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncSteps(isManualRefresh: false);
    }
  }

  Future<void> _syncSteps({bool isManualRefresh = false}) async {
    final hcService = ref.read(healthConnectServiceProvider);
    final dailyLogRepo = ref.read(dailyLogRepoProvider);
    final habitRepo = ref.read(habitRepoProvider);

    final isAuth = await hcService.isAuthorized();
    if (!isAuth) return;

    // Sync today's steps
    await hcService.syncTodayAndAutoCompleteHabit(dailyLogRepo, habitRepo);

    // Sync last 7 days (Samsung Health can revise recent totals)
    await hcService.syncLast7Days(dailyLogRepo, habitRepo);

    // Backfill if first time
    if (!hcService.isBackfillDone) {
      await hcService.backfillLast90Days(dailyLogRepo, habitRepo);
    }

    // Refresh UI
    ref.invalidate(dailyLogProvider);
    ref.invalidate(habitCompletionsProvider);
    
    // Fetch dynamic coach note only on manual refresh
    if (isManualRefresh) {
      ref.read(coachNoteProvider.notifier).fetchNote(force: true);
    }
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: context.colors.primary, size: 18),
            SizedBox(width: 6),
          ],
          Text(
            title,
            style: TextStyle(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: context.colors.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(workoutPlanProvider);

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.primary,
          onRefresh: () => _syncSteps(isManualRefresh: true),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                
                // Coach Notes
                CoachNotesCard(),

                // Week Calendar Strip (Wrapped in card inside widget now)
                WeekCalendarStrip(),
                  
                SizedBox(height: 24),

                // Today's Workouts
                if (plan != null && plan.days.isNotEmpty) ...[
                  _WorkoutsSection(plan: plan),
                  SizedBox(height: 24),
                ],

                // Meals Section
                _buildSectionHeader('MEALS'),
                MealsCard(),
                SizedBox(height: 24),

                // Habits Section
                _HabitsSectionHeader(),
                HabitsCard(),
                SizedBox(height: 24),

                // Daily Progress Section
                _buildSectionHeader('DAILY PROGRESS', icon: Icons.show_chart_rounded),
                SizedBox(height: 12),
                DailyProgressGrid(),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitsSectionHeader extends ConsumerWidget {
  const _HabitsSectionHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final completions = ref.watch(habitCompletionsProvider);
    final dailyLog = ref.watch(dailyLogProvider);
    final completedCount = habits.where((h) => isHabitCompleted(h, completions, dailyLog)).length;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'HABITS ($completedCount/${habits.length})',
            style: TextStyle(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: context.colors.primary,
              fontSize: 13,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ManageHabitsScreen()));
            },
            child: Icon(Icons.edit_rounded, color: context.colors.primary, size: 18),
          ),
        ],
      ),
    );
  }
}

class _WorkoutsSection extends ConsumerWidget {
  const _WorkoutsSection({required this.plan});

  final dynamic plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutPlan = ref.watch(workoutPlanProvider);
    final phaseProgress = ref.watch(phaseProgressProvider);
    if (workoutPlan == null || workoutPlan.days.isEmpty) return SizedBox();

    final dateStr = ref.watch(dateStringProvider);
    final weekday = DateTime.parse(dateStr).weekday;
    
    final selectedDate = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = selectedDate.isAfter(today);

    final isSunday = weekday == DateTime.sunday;
    final dayIndex = isSunday ? 0 : (weekday - 1).clamp(0, workoutPlan.days.length - 1);
    
    // Find the correct day object
    final dayIdTarget = isSunday ? 'Rest' : workoutPlan.days[dayIndex].dayId;
    final day = workoutPlan.days.firstWhere(
        (d) => d.dayId == dayIdTarget,
        orElse: () => workoutPlan.days[dayIndex]);
    
    final logRepo = ref.read(exerciseLogRepoProvider);
    final isWholeDayCompleted = ref.watch(dailyLogProvider).workoutCompleted;
    
    List<Widget> cards = [];
    int completedCount = 0;
    
    if (isSunday || day.sections.isEmpty) {
      cards.add(_buildCard(
        context,
        title: 'Rest Day',
        subtitle: 'Take a break and recover',
        isCompleted: isWholeDayCompleted, 
        isFuture: isFuture,
        isRest: true,
      ));
      if (isWholeDayCompleted) completedCount = 1;
    } else {
      for (int i = 0; i < day.sections.length; i++) {
        final sec = day.sections[i];
        
        bool isCompleted = false;
        if (sec.exercises.isNotEmpty) {
          isCompleted = sec.exercises.every((ex) => logRepo.hasLog(dateStr, ex.name));
        }
        if (isCompleted) completedCount++;
        
        String title = (i == 0) ? day.dayId : sec.title;
        if (sec.title.toLowerCase().contains('cooldown') || sec.title.toLowerCase().contains('cool down')) {
          title = 'Cool down';
        }
        
        String subtitle = (i == 0) ? 'Complete your scheduled workout' : '${sec.exercises.length} exercises';
        
        cards.add(Padding(
          padding: EdgeInsets.only(top: 8),
          child: _buildCard(
            context,
            title: title,
            subtitle: subtitle,
            isCompleted: isCompleted,
            isFuture: isFuture,
            isRest: false,
            onTap: () => context.go('/home/workout/${day.dayId}?section=$i'),
          ),
        ));
      }
    }
    
    final total = (isSunday || day.sections.isEmpty) ? 1 : day.sections.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WORKOUTS ($completedCount/$total)',
                style: TextStyle(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: context.colors.primary,
                  fontSize: 13,
                ),
              ),
              if (phaseProgress.isPhaseActive)
                Row(
                  children: [
                    Text(
                      'Week ${phaseProgress.currentWeek} of ${phaseProgress.totalWeeks}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: (phaseProgress.currentWeek - 1) / phaseProgress.totalWeeks,
                        strokeWidth: 2,
                        backgroundColor: context.colors.primary.withValues(alpha: 0.2),
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: cards),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isFuture,
    required bool isRest,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isFuture ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isCompleted ? Border.all(color: context.colors.green.withValues(alpha: 0.3), width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: context.colors.textLight.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.colors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.colors.textMedium,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            if (isCompleted)
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: context.colors.green, size: 20),
              )
            else if (isRest)
              Icon(Icons.self_improvement_rounded, color: context.colors.textLight, size: 26)
            else
              Icon(Icons.fitness_center_outlined, color: context.colors.textDark, size: 26),
          ],
        ),
      ),
    );
  }
}
