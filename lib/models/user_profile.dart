class UserProfile {
  final String name;
  final String? photoPath;
  final double height; // in cm
  final double? targetWeight; // in kg
  final bool useKg;
  final String? activeMealPlan;
  final String? activeWorkoutPlan;
  final List<Map<String, dynamic>> customHabits;

  UserProfile({
    this.name = 'Mamatha',
    this.photoPath,
    this.height = 160,
    this.targetWeight,
    this.useKg = true,
    this.activeMealPlan,
    this.activeWorkoutPlan,
    this.customHabits = const [],
  });

  double get heightInMeters => height / 100;

  double? computeBmi(double? weight) {
    if (weight == null || height <= 0) return null;
    return weight / (heightInMeters * heightInMeters);
  }

  String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  double convertWeight(double kg) {
    return useKg ? kg : kg * 2.20462;
  }

  String get weightUnit => useKg ? 'kg' : 'lb';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'Mamatha',
      photoPath: json['photoPath'] as String?,
      height: (json['height'] as num?)?.toDouble() ?? 160,
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      useKg: json['useKg'] as bool? ?? true,
      activeMealPlan: json['activeMealPlan'] as String?,
      activeWorkoutPlan: json['activeWorkoutPlan'] as String?,
      customHabits: (json['customHabits'] as List?)
              ?.map((h) => Map<String, dynamic>.from(h as Map))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (photoPath != null) 'photoPath': photoPath,
        'height': height,
        if (targetWeight != null) 'targetWeight': targetWeight,
        'useKg': useKg,
        if (activeMealPlan != null) 'activeMealPlan': activeMealPlan,
        if (activeWorkoutPlan != null) 'activeWorkoutPlan': activeWorkoutPlan,
        'customHabits': customHabits,
      };

  UserProfile copyWith({
    String? name,
    String? photoPath,
    double? height,
    double? targetWeight,
    bool? useKg,
    String? activeMealPlan,
    String? activeWorkoutPlan,
    List<Map<String, dynamic>>? customHabits,
  }) {
    return UserProfile(
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      height: height ?? this.height,
      targetWeight: targetWeight ?? this.targetWeight,
      useKg: useKg ?? this.useKg,
      activeMealPlan: activeMealPlan ?? this.activeMealPlan,
      activeWorkoutPlan: activeWorkoutPlan ?? this.activeWorkoutPlan,
      customHabits: customHabits ?? this.customHabits,
    );
  }
}
