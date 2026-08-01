import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trufit_bodamma/screens/onboarding/onboarding_screen.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/repositories/profile_repository.dart';
import 'package:trufit_bodamma/models/habit.dart';
import '../../helpers/test_hive_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late HabitRepository habitRepo;
  late ProfileRepository profileRepo;
  late ProviderContainer container;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    await setUpTestHive();
    
    habitRepo = HabitRepository();
    await habitRepo.init();
    
    // Seed with all defaults initially
    for (final h in Habit.defaults) {
      await habitRepo.saveHabit(h);
    }
    
    profileRepo = ProfileRepository();
    await profileRepo.init();

    container = ProviderContainer(
      overrides: [
        habitRepoProvider.overrideWithValue(habitRepo),
        profileRepoProvider.overrideWithValue(profileRepo),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await tearDownTestHive();
  });

  testWidgets('Deselecting habit in onboarding removes it from repository', (WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    // Initial state check: all default habits should be in the repo
    expect(habitRepo.getHabits().length, Habit.defaults.length);

    // Skip to goals page
    // Page 0: Welcome -> Tap "Get Started"
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Page 1: Profile -> Fill name and Tap "Continue"
    await tester.enterText(find.byType(TextField).first, 'Test User');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Page 2: Goals
    // Deselect the "Drink 2L Water" habit
    final waterHabitText = find.text('Drink 2L Water');
    expect(waterHabitText, findsOneWidget);
    
    // The habit list tiles are CheckboxListTile or similar, let's tap it
    await tester.tap(waterHabitText);
    await tester.pumpAndSettle();

    // Tap "Continue" to save goals
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Check repository
    final savedHabits = habitRepo.getHabits();
    
    // Should not contain the water habit
    expect(savedHabits.any((h) => h.id == 'water'), isFalse);
    
    // Should still contain other habits like sleep and walk
    expect(savedHabits.any((h) => h.id == 'sleep'), isTrue);
    expect(savedHabits.any((h) => h.id == 'walk'), isTrue);
  });
}
