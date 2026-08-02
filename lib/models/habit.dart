import 'daily_log.dart';

enum HabitType { checkbox, counter, autoSteps, autoSleep }

class Habit {
  final String id;
  final String name;
  final String icon;
  final HabitType type;
  final String unit;
  final double target;
  final double step;
  final DateTime createdAt;
  final int order;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    this.type = HabitType.checkbox,
    this.unit = '',
    required this.target,
    this.step = 1.0,
    DateTime? createdAt,
    this.order = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'check',
      type: HabitType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HabitType.checkbox,
      ),
      unit: json['unit'] as String? ?? '',
      target: (json['target'] as num?)?.toDouble() ?? 1.0,
      step: (json['step'] as num?)?.toDouble() ?? 1.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.parse('2020-01-01'),
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'type': type.name,
        'unit': unit,
        'target': target,
        'step': step,
        'createdAt': createdAt.toIso8601String(),
        'order': order,
      };

  Habit copyWith({
    String? name,
    String? icon,
    HabitType? type,
    String? unit,
    double? target,
    double? step,
    int? order,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      target: target ?? this.target,
      step: step ?? this.step,
      createdAt: createdAt,
      order: order ?? this.order,
    );
  }

  static List<Habit> defaults = [
    Habit(
        id: 'sleep',
        name: 'Sleep 8 hours',
        icon: 'bedtime',
        type: HabitType.autoSleep,
        unit: 'hours',
        target: 8.0,
        createdAt: DateTime.parse('2020-01-01'),
        order: 0),
    Habit(
        id: 'walk',
        name: 'Walk 8000 steps',
        icon: 'walk',
        type: HabitType.autoSteps,
        unit: 'steps',
        target: 8000.0,
        createdAt: DateTime.parse('2020-01-01'),
        order: 1),
    Habit(
        id: 'water',
        name: 'Drink 3 L of water',
        icon: 'water',
        type: HabitType.checkbox,
        unit: 'L',
        target: 3.0,
        step: 1.0,
        createdAt: DateTime.parse('2020-01-01'),
        order: 2),
  ];
}

class HabitCompletion {
  final String date;
  final Map<String, dynamic> completions; // habitId -> bool or num
  final Map<String, String> overrides; // habitId -> 'done', 'notDone'

  HabitCompletion({
    required this.date,
    Map<String, dynamic>? completions,
    Map<String, String>? overrides,
  }) : completions = completions ?? {},
       overrides = overrides ?? {};

  bool isCompleted(Habit habit) {
    final val = completions[habit.id];
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val >= habit.target;
    return false;
  }

  double getProgress(Habit habit) {
    final val = completions[habit.id];
    if (val == null) return 0.0;
    if (val is bool) return val ? habit.target : 0.0;
    if (val is num) return val.toDouble();
    return 0.0;
  }

  HabitCompletion toggleCheckbox(String habitId) {
    final newCompletions = Map<String, dynamic>.from(completions);
    final current = newCompletions[habitId];
    newCompletions[habitId] = current is bool ? !current : true;
    return HabitCompletion(date: date, completions: newCompletions, overrides: overrides);
  }

  HabitCompletion updateProgress(String habitId, double progress) {
    final newCompletions = Map<String, dynamic>.from(completions);
    newCompletions[habitId] = progress;
    // Clearing override if the user manually uses +/- buttons 
    // to return to normal tracking.
    final newOverrides = Map<String, String>.from(overrides);
    newOverrides.remove(habitId);
    
    return HabitCompletion(date: date, completions: newCompletions, overrides: newOverrides);
  }

  HabitCompletion setOverride(String habitId, String? overrideValue) {
    final newOverrides = Map<String, String>.from(overrides);
    if (overrideValue == null) {
      newOverrides.remove(habitId);
    } else {
      newOverrides[habitId] = overrideValue;
    }
    return HabitCompletion(date: date, completions: completions, overrides: newOverrides);
  }

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      date: json['date'] as String,
      completions: (json['completions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v),
          ) ??
          {},
      overrides: (json['overrides'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'completions': completions,
        'overrides': overrides,
      };
}

// Helpers
double getHabitProgress(Habit habit, HabitCompletion completions, DailyLog dailyLog) {
  final override = completions.overrides[habit.id];
  if (override == 'done') return habit.target;
  if (override == 'notDone') return 0.0;

  switch (habit.type) {
    case HabitType.checkbox:
    case HabitType.counter:
      return completions.getProgress(habit);
    case HabitType.autoSteps:
      return (dailyLog.steps ?? 0).toDouble();
    case HabitType.autoSleep:
      return dailyLog.sleepHours ?? 0.0;
  }
}

bool isHabitCompleted(Habit habit, HabitCompletion completions, DailyLog dailyLog) {
  final override = completions.overrides[habit.id];
  if (override == 'done') return true;
  if (override == 'notDone') return false;

  if (habit.type == HabitType.checkbox) {
    return completions.isCompleted(habit);
  }
  return getHabitProgress(habit, completions, dailyLog) >= habit.target;
}
