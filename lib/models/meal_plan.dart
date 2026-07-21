class MealPlan {
  final String planName;
  final List<Meal> meals;
  final int totalCalories;

  MealPlan({
    required this.planName,
    required this.meals,
    required this.totalCalories,
  });

  int get completedMeals => meals.where((m) => m.isCompleted).length;
  int get completedCalories =>
      meals.where((m) => m.isCompleted).fold(0, (sum, m) => sum + m.calories);

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final meals =
        (json['meals'] as List).map((m) => Meal.fromJson(m as Map<String, dynamic>)).toList();
    return MealPlan(
      planName: json['planName'] as String,
      meals: meals,
      totalCalories: json['totalCalories'] as int? ??
          meals.fold(0, (sum, m) => sum + m.calories),
    );
  }

  Map<String, dynamic> toJson() => {
        'planName': planName,
        'meals': meals.map((m) => m.toJson()).toList(),
        'totalCalories': totalCalories,
      };

  MealPlan copyWith({List<Meal>? meals}) {
    return MealPlan(
      planName: planName,
      meals: meals ?? this.meals,
      totalCalories: totalCalories,
    );
  }
}

class Meal {
  final String name;
  final String type; // breakfast, lunch, snack, dinner
  final List<MealItem> items;
  final int calories;
  final bool isCompleted;

  Meal({
    required this.name,
    required this.type,
    required this.items,
    required this.calories,
    this.isCompleted = false,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: json['name'] as String,
      type: json['type'] as String,
      items: (json['items'] as List?)
              ?.map((i) => MealItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      calories: json['calories'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'items': items.map((i) => i.toJson()).toList(),
        'calories': calories,
        'isCompleted': isCompleted,
      };

  Meal copyWith({bool? isCompleted}) {
    return Meal(
      name: name,
      type: type,
      items: items,
      calories: calories,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  String get icon {
    switch (type) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'snack':
        return '🍎';
      case 'dinner':
        return '🌙';
      default:
        return '🍽️';
    }
  }
}

class MealItem {
  final String name;
  final String quantity;
  final int calories;

  MealItem({
    required this.name,
    required this.quantity,
    required this.calories,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      name: json['name'] as String,
      quantity: json['quantity'] as String? ?? '',
      calories: json['calories'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'calories': calories,
      };
}
