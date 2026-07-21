class DailyLog {
  final String date; // yyyy-MM-dd
  final double? weight;
  final int? steps;
  final double? sleepHours;
  final double? bodyFat;
  final bool workoutCompleted;
  final String? workoutDayId;

  DailyLog({
    required this.date,
    this.weight,
    this.steps,
    this.sleepHours,
    this.bodyFat,
    this.workoutCompleted = false,
    this.workoutDayId,
  });

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      date: json['date'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
      steps: json['steps'] as int?,
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      bodyFat: (json['bodyFat'] as num?)?.toDouble(),
      workoutCompleted: json['workoutCompleted'] as bool? ?? false,
      workoutDayId: json['workoutDayId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        if (weight != null) 'weight': weight,
        if (steps != null) 'steps': steps,
        if (sleepHours != null) 'sleepHours': sleepHours,
        if (bodyFat != null) 'bodyFat': bodyFat,
        'workoutCompleted': workoutCompleted,
        if (workoutDayId != null) 'workoutDayId': workoutDayId,
      };

  DailyLog copyWith({
    double? weight,
    int? steps,
    double? sleepHours,
    double? bodyFat,
    bool? workoutCompleted,
    String? workoutDayId,
  }) {
    return DailyLog(
      date: date,
      weight: weight ?? this.weight,
      steps: steps ?? this.steps,
      sleepHours: sleepHours ?? this.sleepHours,
      bodyFat: bodyFat ?? this.bodyFat,
      workoutCompleted: workoutCompleted ?? this.workoutCompleted,
      workoutDayId: workoutDayId ?? this.workoutDayId,
    );
  }

  bool get hasAnyActivity =>
      weight != null ||
      steps != null ||
      sleepHours != null ||
      workoutCompleted;
}
