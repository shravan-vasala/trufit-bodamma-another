import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:math';

import '../models/feature_availability.dart';

class CoachService {
  final String? apiKey;

  CoachService({this.apiKey});

  FeatureAvailability get availability {
    if (apiKey == null || apiKey!.isEmpty) return FeatureAvailability.disabled;
    return FeatureAvailability.available;
  }

  Future<String> generateNote({
    required String userName,
    required String coachName,
    required int steps,
    required double sleep,
    required int habitsDone,
    required int habitsTotal,
    required int calories,
    required int workoutsDone,
    required int workoutsTotal,
    required double yesterdayHabitRate,
    required String weightTrend,
    required bool isRestDay,
    required int daysSinceLastWorkout,
  }) async {
    final coachLabel = coachName.trim().isEmpty ? 'Coach' : coachName.trim();

    // If no API key, use fallback templated note
    if (apiKey == null || apiKey!.isEmpty) {
      return _generateTemplatedNote(
        userName, steps, sleep, habitsDone, habitsTotal, calories, workoutsDone, workoutsTotal, isRestDay, daysSinceLastWorkout
      );
    }

    // Call Gemini
    final prompt = '''
You are an enthusiastic, supportive personal fitness coach named $coachLabel. 
Your client's name is ${userName.isEmpty ? 'friend' : userName}.

Here is their progress and context for today:
- Steps: $steps
- Sleep: ${sleep.toStringAsFixed(1)} hours
- Calories tracked: $calories
- Habits completed today: $habitsDone / $habitsTotal (Yesterday's rate: ${(yesterdayHabitRate * 100).toStringAsFixed(0)}%)
- Workouts completed today: $workoutsDone / $workoutsTotal
- Weight trend (last 7 days): $weightTrend
- Is today a scheduled rest day?: ${isRestDay ? "Yes" : "No"}
${isRestDay ? "- Days since their last workout: $daysSinceLastWorkout" : ""}

Write a very brief (1-2 short sentences) encouraging note for them right now. 
Focus on what they've done well today, their recent trends, or what they should focus on next today. 
Use a friendly, casual tone and 1-2 emojis. Do not use quotes.
''';

    final modelsToTry = [
      'gemini-flash-latest',
      'gemini-2.5-flash',
      'gemini-2.0-flash',
    ];

    String lastError = '';
    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey!,
          generationConfig: GenerationConfig(temperature: 0.7),
        );
        final response = await model.generateContent([Content.text(prompt)]);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!.trim().replaceAll('"', '');
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    debugPrint('Gemini Coach Note failed: $lastError');
    // Fallback if Gemini fails
    return _generateTemplatedNote(
      userName, steps, sleep, habitsDone, habitsTotal, calories, workoutsDone, workoutsTotal, isRestDay, daysSinceLastWorkout
    );
  }

  String _generateTemplatedNote(
    String name, int steps, double sleep, int habitsDone, int habitsTotal, int calories, int workoutsDone, int workoutsTotal, bool isRestDay, int daysSinceLastWorkout
  ) {
    final n = name.isNotEmpty ? name : 'friend';
    final random = Random();
    final hour = DateTime.now().hour;

    // Time of day specific generic messages
    List<String> generics = [];

    if (hour < 12) {
      generics = [
        "Good morning, $n! Let's make today amazing. 🌅",
        "Rise and shine, $n! Drink some water and start the day strong. 💧",
        "Morning, $n! Today is a blank canvas. Let's crush it! 🎨",
        "Wakey wakey, $n! Time to get those endorphins flowing. ⚡",
        "Good morning! Let's start the day with a healthy choice, $n. 🍎",
        "A new day is a new opportunity, $n. Go get 'em! 🚀",
        "Morning, $n! Take a deep breath and let's tackle your goals. 🧘"
      ];
    } else if (hour < 18) {
      generics = [
        "Good afternoon, $n! Keep that momentum going! 🔥",
        "Hope your day is going well, $n. Remember to stretch! 🤸",
        "Afternoon slump? Not for you, $n! Stay focused. 👀",
        "Halfway through the day, $n! Keep up the great work. ⭐",
        "Good afternoon! Don't forget to hydrate, $n. 🥤",
        "Keep crushing it this afternoon, $n! 💪",
        "You've got this, $n! The day isn't over yet. ⏱️"
      ];
    } else {
      generics = [
        "Good evening, $n! Time to wind down and recover. 🌙",
        "Evening, $n! Reflect on today's wins, no matter how small. 🏆",
        "Great work today, $n. Rest up for tomorrow! 🛌",
        "Good evening! Make sure to get some quality sleep tonight, $n. 💤",
        "Day is done, $n. Be proud of the effort you put in! 👏",
        "Evening, $n! Recovery is just as important as the workout. 🛁",
        "Time to relax, $n. You earned it today! 🛋️"
      ];
    }
    
    // Performance based overrides
    if (!isRestDay && workoutsDone == workoutsTotal && workoutsTotal > 0) {
      final messages = [
        "Awesome job crushing your workout today, $n! 💪 Make sure to rest up and hydrate.",
        "You absolutely nailed your workout, $n! 🔥 I'm so proud of you.",
        "Workout complete! Way to show up for yourself today, $n. 🏅",
        "Boom! Workout done. Your body will thank you later, $n. 🙌"
      ];
      return messages[random.nextInt(messages.length)];
    }
    
    if (isRestDay && daysSinceLastWorkout == 0) {
      final messages = [
        "It's a rest day, $n! Enjoy the recovery, you earned it yesterday. 🛋️",
        "Take it easy today, $n. Your muscles need time to rebuild! 🧘",
        "Rest day vibes! Listen to your body and just relax today, $n. 🍃"
      ];
      return messages[random.nextInt(messages.length)];
    }

    if (steps > 10000) {
      final messages = [
        "Over 10K steps?! Look at you go, $n! 🏃 Keep that momentum up!",
        "You're a walking machine today, $n! Incredible step count. 👟",
        "10,000 steps crushed! Your energy is inspiring, $n. ⚡"
      ];
      return messages[random.nextInt(messages.length)];
    }

    if (habitsDone == habitsTotal && habitsTotal > 0) {
      final messages = [
        "Perfect habit streak today! 🌟 Consistency is the secret to results, $n.",
        "All habits checked off! You're building an incredible foundation, $n. 🧱",
        "100% on habits today! That's how we build lasting change, $n. 🎯"
      ];
      return messages[random.nextInt(messages.length)];
    }
    
    return generics[random.nextInt(generics.length)];
  }
}
