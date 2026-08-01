class UserProfile {
  final String name;
  final String? photoPath;
  final double height; // in cm
  final double? targetWeight; // in kg
  final bool useKg;
  final int targetCalories;
  final String? activeWorkoutPlan;
  final String? activeMealPlan;
  final List<Map<String, dynamic>> customHabits;
  final List<Map<String, dynamic>> customMealSlots;
  final String? geminiApiKey;
  final bool restTimerSound;
  final bool restTimerVibration;
  final int targetProteinG;
  final int targetCarbsG;
  final int targetFatG;
  final DateTime? planStartDate;
  final int currentPhaseWeek;
  UserProfile({
    this.name = '',
    this.photoPath,
    this.height = 160,
    this.targetWeight,
    this.useKg = true,
    this.targetCalories = 1397,
    this.activeWorkoutPlan,
    this.activeMealPlan,
    this.customHabits = const [],
    this.customMealSlots = const [
      {'id': 'breakfast', 'name': 'Breakfast', 'emoji': '🍳', 'isDefault': true},
      {'id': 'lunch', 'name': 'Lunch', 'emoji': '🍛', 'isDefault': true},
      {'id': 'snack', 'name': 'Snack', 'emoji': '🍎', 'isDefault': true},
      {'id': 'dinner', 'name': 'Dinner', 'emoji': '🍽️', 'isDefault': true},
    ],
    this.geminiApiKey,
    this.restTimerSound = true,
    this.restTimerVibration = true,
    this.targetProteinG = 120,
    this.targetCarbsG = 150,
    this.targetFatG = 50,
    this.planStartDate,
    this.currentPhaseWeek = 1,
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
      name: json['name'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
      height: (json['height'] as num?)?.toDouble() ?? 160,
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      useKg: json['useKg'] as bool? ?? true,
      targetCalories: (json['targetCalories'] as num?)?.toInt() ?? 1397,
      activeWorkoutPlan: json['activeWorkoutPlan'] as String?,
      activeMealPlan: json['activeMealPlan'] as String?,
      customHabits: (json['customHabits'] as List?)
              ?.map((h) => Map<String, dynamic>.from(h as Map))
              .toList() ??
          [],
      customMealSlots: (json['customMealSlots'] as List?)
              ?.map((h) => Map<String, dynamic>.from(h as Map))
              .toList() ??
          [
            {'id': 'breakfast', 'name': 'Breakfast', 'emoji': '🍳', 'isDefault': true},
            {'id': 'lunch', 'name': 'Lunch', 'emoji': '🍛', 'isDefault': true},
            {'id': 'snack', 'name': 'Snack', 'emoji': '🍎', 'isDefault': true},
            {'id': 'dinner', 'name': 'Dinner', 'emoji': '🍽️', 'isDefault': true},
          ],
      geminiApiKey: json['geminiApiKey'] as String?,
      restTimerSound: json['restTimerSound'] as bool? ?? true,
      restTimerVibration: json['restTimerVibration'] as bool? ?? true,
      targetProteinG: (json['targetProteinG'] as num?)?.toInt() ?? 120,
      targetCarbsG: (json['targetCarbsG'] as num?)?.toInt() ?? 150,
      targetFatG: (json['targetFatG'] as num?)?.toInt() ?? 50,
      planStartDate: json['planStartDate'] != null ? DateTime.parse(json['planStartDate'] as String) : null,
      currentPhaseWeek: (json['currentPhaseWeek'] as num?)?.toInt() ?? 1,
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
        if (activeMealPlan != null) 'activeMealPlan': activeMealPlan,
        'customHabits': customHabits,
        'customMealSlots': customMealSlots,
        'restTimerSound': restTimerSound,
        'restTimerVibration': restTimerVibration,
        'targetProteinG': targetProteinG,
        'targetCarbsG': targetCarbsG,
        'targetFatG': targetFatG,
        if (planStartDate != null) 'planStartDate': planStartDate!.toIso8601String(),
        'currentPhaseWeek': currentPhaseWeek,
      };

  UserProfile copyWith({
    String? name,
    String? photoPath,
    double? height,
    double? targetWeight,
    bool? useKg,
    int? targetCalories,
    String? activeWorkoutPlan,
    String? activeMealPlan,
    List<Map<String, dynamic>>? customHabits,
    List<Map<String, dynamic>>? customMealSlots,
    String? geminiApiKey,
    bool? restTimerSound,
    bool? restTimerVibration,
    int? targetProteinG,
    int? targetCarbsG,
    int? targetFatG,
    DateTime? planStartDate,
    int? currentPhaseWeek,
    bool clearPhoto = false,
    bool clearPlanStart = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      height: height ?? this.height,
      targetWeight: targetWeight ?? this.targetWeight,
      useKg: useKg ?? this.useKg,
      targetCalories: targetCalories ?? this.targetCalories,
      activeWorkoutPlan: activeWorkoutPlan ?? this.activeWorkoutPlan,
      activeMealPlan: activeMealPlan ?? this.activeMealPlan,
      customHabits: customHabits ?? this.customHabits,
      customMealSlots: customMealSlots ?? this.customMealSlots,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      restTimerSound: restTimerSound ?? this.restTimerSound,
      restTimerVibration: restTimerVibration ?? this.restTimerVibration,
      targetProteinG: targetProteinG ?? this.targetProteinG,
      targetCarbsG: targetCarbsG ?? this.targetCarbsG,
      targetFatG: targetFatG ?? this.targetFatG,
      planStartDate: clearPlanStart ? null : (planStartDate ?? this.planStartDate),
      currentPhaseWeek: currentPhaseWeek ?? this.currentPhaseWeek,
    );
  }
}
