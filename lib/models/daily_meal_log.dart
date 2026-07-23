class DailyMealLog {
  final String date; // yyyy-MM-dd
  final MealSlotLog? breakfast;
  final MealSlotLog? lunch;
  final MealSlotLog? snack;
  final MealSlotLog? dinner;

  DailyMealLog({
    required this.date,
    this.breakfast,
    this.lunch,
    this.snack,
    this.dinner,
  });

  int get totalCalories =>
      (breakfast?.totalCalories ?? 0) +
      (lunch?.totalCalories ?? 0) +
      (snack?.totalCalories ?? 0) +
      (dinner?.totalCalories ?? 0);

  double get totalProtein =>
      (breakfast?.totalProtein ?? 0) +
      (lunch?.totalProtein ?? 0) +
      (snack?.totalProtein ?? 0) +
      (dinner?.totalProtein ?? 0);

  double get totalCarbs =>
      (breakfast?.totalCarbs ?? 0) +
      (lunch?.totalCarbs ?? 0) +
      (snack?.totalCarbs ?? 0) +
      (dinner?.totalCarbs ?? 0);

  double get totalFat =>
      (breakfast?.totalFat ?? 0) +
      (lunch?.totalFat ?? 0) +
      (snack?.totalFat ?? 0) +
      (dinner?.totalFat ?? 0);

  int get loggedSlotsCount {
    int count = 0;
    if (breakfast != null) count++;
    if (lunch != null) count++;
    if (snack != null) count++;
    if (dinner != null) count++;
    return count;
  }

  factory DailyMealLog.fromJson(Map<String, dynamic> json) {
    return DailyMealLog(
      date: json['date'] as String,
      breakfast: json['breakfast'] != null
          ? MealSlotLog.fromJson(json['breakfast'] as Map<String, dynamic>)
          : null,
      lunch: json['lunch'] != null
          ? MealSlotLog.fromJson(json['lunch'] as Map<String, dynamic>)
          : null,
      snack: json['snack'] != null
          ? MealSlotLog.fromJson(json['snack'] as Map<String, dynamic>)
          : null,
      dinner: json['dinner'] != null
          ? MealSlotLog.fromJson(json['dinner'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        if (breakfast != null) 'breakfast': breakfast!.toJson(),
        if (lunch != null) 'lunch': lunch!.toJson(),
        if (snack != null) 'snack': snack!.toJson(),
        if (dinner != null) 'dinner': dinner!.toJson(),
      };

  DailyMealLog copyWith({
    MealSlotLog? breakfast,
    MealSlotLog? lunch,
    MealSlotLog? snack,
    MealSlotLog? dinner,
    bool clearBreakfast = false,
    bool clearLunch = false,
    bool clearSnack = false,
    bool clearDinner = false,
  }) {
    return DailyMealLog(
      date: date,
      breakfast: clearBreakfast ? null : (breakfast ?? this.breakfast),
      lunch: clearLunch ? null : (lunch ?? this.lunch),
      snack: clearSnack ? null : (snack ?? this.snack),
      dinner: clearDinner ? null : (dinner ?? this.dinner),
    );
  }
}

class MealSlotLog {
  final String? photoPath;
  final List<MealItemLog> items;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final String? confidence; // "high", "medium", "low"

  MealSlotLog({
    this.photoPath,
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.confidence,
  });

  factory MealSlotLog.fromJson(Map<String, dynamic> json) {
    return MealSlotLog(
      photoPath: json['photoPath'] as String?,
      items: (json['items'] as List?)
              ?.map((i) => MealItemLog.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      totalCalories: json['totalCalories'] as int? ?? 0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0.0,
      confidence: json['confidence'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (photoPath != null) 'photoPath': photoPath,
        'items': items.map((i) => i.toJson()).toList(),
        'totalCalories': totalCalories,
        'totalProtein': totalProtein,
        'totalCarbs': totalCarbs,
        'totalFat': totalFat,
        if (confidence != null) 'confidence': confidence,
      };
}

class MealItemLog {
  final String name;
  final String portion;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  MealItemLog({
    required this.name,
    required this.portion,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory MealItemLog.fromJson(Map<String, dynamic> json) {
    return MealItemLog(
      name: json['name'] as String? ?? 'Unknown',
      portion: json['portion'] as String? ?? '',
      calories: json['calories'] as int? ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'portion': portion,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
      };
}
