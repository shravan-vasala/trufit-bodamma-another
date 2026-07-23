class UserProfile {
  final String name;
  final String? photoPath;
  final double height; // in cm
  final double? targetWeight; // in kg
  final bool useKg;
  final int targetCalories;
  final String? activeWorkoutPlan;
  final List<Map<String, dynamic>> customHabits;
  final String? geminiApiKey;


  UserProfile({
    this.name = 'Mamatha',
    this.photoPath,
    this.height = 160,
    this.targetWeight,
    this.useKg = true,
    this.targetCalories = 1397,
    this.activeWorkoutPlan,
    this.customHabits = const [],
    this.geminiApiKey,
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
      targetCalories: (json['targetCalories'] as num?)?.toInt() ?? 1397,
      activeWorkoutPlan: json['activeWorkoutPlan'] as String?,
      customHabits: (json['customHabits'] as List?)
              ?.map((h) => Map<String, dynamic>.from(h as Map))
              .toList() ??
          [],
      geminiApiKey: json['geminiApiKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (photoPath != null) 'photoPath': photoPath,
        'height': height,
        if (targetWeight != null) 'targetWeight': targetWeight,
        'useKg': useKg,
        'targetCalories': targetCalories,
        if (activeWorkoutPlan != null) 'activeWorkoutPlan': activeWorkoutPlan,
        'customHabits': customHabits,
        if (geminiApiKey != null) 'geminiApiKey': geminiApiKey,
      };

  UserProfile copyWith({
    String? name,
    String? photoPath,
    double? height,
    double? targetWeight,
    bool? useKg,
    int? targetCalories,
    String? activeWorkoutPlan,
    List<Map<String, dynamic>>? customHabits,
    String? geminiApiKey,
  }) {
    return UserProfile(
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      height: height ?? this.height,
      targetWeight: targetWeight ?? this.targetWeight,
      useKg: useKg ?? this.useKg,
      targetCalories: targetCalories ?? this.targetCalories,
      activeWorkoutPlan: activeWorkoutPlan ?? this.activeWorkoutPlan,
      customHabits: customHabits ?? this.customHabits,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }
}
