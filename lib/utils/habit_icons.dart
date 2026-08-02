import 'package:flutter/material.dart';

/// Habit icons are Material [IconData], stored as string keys.
/// Legacy emoji values still resolve for existing saved habits.
class HabitIcons {
  HabitIcons._();

  static const List<({String id, IconData icon})> options = [
    (id: 'check', icon: Icons.check_circle_outline_rounded),
    (id: 'bedtime', icon: Icons.bedtime_rounded),
    (id: 'walk', icon: Icons.directions_walk_rounded),
    (id: 'water', icon: Icons.water_drop_rounded),
    (id: 'mind', icon: Icons.self_improvement_rounded),
    (id: 'book', icon: Icons.menu_book_rounded),
    (id: 'meds', icon: Icons.medication_rounded),
    (id: 'food', icon: Icons.restaurant_rounded),
    (id: 'train', icon: Icons.fitness_center_rounded),
    (id: 'run', icon: Icons.directions_run_rounded),
    (id: 'smoke_free', icon: Icons.smoke_free_rounded),
    (id: 'greens', icon: Icons.eco_rounded),
  ];

  static IconData resolve(String keyOrEmoji) {
    switch (keyOrEmoji) {
      case '😴':
      case 'bedtime':
        return Icons.bedtime_rounded;
      case '🚶':
      case 'walk':
        return Icons.directions_walk_rounded;
      case '🏃':
      case 'run':
        return Icons.directions_run_rounded;
      case '💧':
      case 'water':
        return Icons.water_drop_rounded;
      case '✅':
      case 'check':
        return Icons.check_circle_outline_rounded;
      case '🧘':
      case 'mind':
        return Icons.self_improvement_rounded;
      case '📚':
      case 'book':
        return Icons.menu_book_rounded;
      case '💊':
      case 'meds':
        return Icons.medication_rounded;
      case '🍎':
      case 'food':
        return Icons.restaurant_rounded;
      case '🏋️':
      case 'train':
        return Icons.fitness_center_rounded;
      case '🚭':
      case 'smoke_free':
        return Icons.smoke_free_rounded;
      case '🥦':
      case 'greens':
        return Icons.eco_rounded;
      default:
        for (final o in options) {
          if (o.id == keyOrEmoji) return o.icon;
        }
        return Icons.check_circle_outline_rounded;
    }
  }

  /// Prefer storing stable keys when saving.
  static String normalize(String keyOrEmoji) {
    switch (keyOrEmoji) {
      case '😴':
        return 'bedtime';
      case '🚶':
        return 'walk';
      case '🏃':
        return 'run';
      case '💧':
        return 'water';
      case '✅':
        return 'check';
      case '🧘':
        return 'mind';
      case '📚':
        return 'book';
      case '💊':
        return 'meds';
      case '🍎':
        return 'food';
      case '🏋️':
        return 'train';
      case '🚭':
        return 'smoke_free';
      case '🥦':
        return 'greens';
      default:
        for (final o in options) {
          if (o.id == keyOrEmoji) return o.id;
        }
        return 'check';
    }
  }
}
