class Habit {
  final String id;
  final String name;
  final String icon;
  final String unit;
  final double target;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.unit,
    required this.target,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '✅',
      unit: json['unit'] as String? ?? '',
      target: (json['target'] as num?)?.toDouble() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'unit': unit,
        'target': target,
      };

  static List<Habit> defaults = [
    Habit(id: 'sleep', name: 'Sleep 8 hours', icon: '😴', unit: 'hours', target: 8),
    Habit(id: 'walk', name: 'Walk 8000 steps', icon: '🚶', unit: 'steps', target: 8000),
    Habit(id: 'water', name: 'Drink 3 ltr of water', icon: '💧', unit: 'liters', target: 3),
  ];
}

class HabitCompletion {
  final String date;
  final Map<String, bool> completions; // habitId -> completed

  HabitCompletion({
    required this.date,
    Map<String, bool>? completions,
  }) : completions = completions ?? {};

  int get completedCount => completions.values.where((v) => v).length;

  bool isCompleted(String habitId) => completions[habitId] ?? false;

  HabitCompletion toggle(String habitId) {
    final newCompletions = Map<String, bool>.from(completions);
    newCompletions[habitId] = !(newCompletions[habitId] ?? false);
    return HabitCompletion(date: date, completions: newCompletions);
  }

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      date: json['date'] as String,
      completions: (json['completions'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as bool)) ??
          {},
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'completions': completions,
      };
}
