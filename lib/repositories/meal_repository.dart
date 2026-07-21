import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/meal_plan.dart';

class MealRepository {
  static const String _planBoxName = 'meal_plans';
  static const String _completionBoxName = 'meal_completions';

  late Box<String> _planBox;
  late Box<String> _completionBox;

  Future<void> init() async {
    _planBox = await Hive.openBox<String>(_planBoxName);
    _completionBox = await Hive.openBox<String>(_completionBoxName);
    await _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    if (_planBox.isEmpty) {
      final jsonStr = await rootBundle.loadString('assets/data/seed_meal_plan.json');
      _planBox.put('mamatha_nonveg', jsonStr);
    }
  }

  MealPlan? getActivePlan() {
    if (_planBox.isEmpty) return null;
    final jsonStr = _planBox.values.first;
    return MealPlan.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  List<MealPlan> getAllPlans() {
    return _planBox.values.map((jsonStr) {
      return MealPlan.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }).toList();
  }

  // Meal completions for a date
  Map<String, bool> getMealCompletions(String date) {
    final jsonStr = _completionBox.get(date);
    if (jsonStr == null) return {};
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, v as bool));
  }

  Future<void> toggleMealCompletion(String date, String mealType) async {
    final completions = getMealCompletions(date);
    completions[mealType] = !(completions[mealType] ?? false);
    await _completionBox.put(date, jsonEncode(completions));
  }

  MealPlan? getPlanWithCompletions(String date) {
    final plan = getActivePlan();
    if (plan == null) return null;
    final completions = getMealCompletions(date);
    final updatedMeals = plan.meals.map((meal) {
      return meal.copyWith(isCompleted: completions[meal.type] ?? false);
    }).toList();
    return plan.copyWith(meals: updatedMeals);
  }

  Future<void> savePlanJson(String key, String jsonStr) async {
    jsonDecode(jsonStr); // validate
    await _planBox.put(key, jsonStr);
  }

  String? getRawPlanJson(String key) {
    return _planBox.get(key);
  }

  List<String> getPlanKeys() {
    return _planBox.keys.cast<String>().toList();
  }
}
