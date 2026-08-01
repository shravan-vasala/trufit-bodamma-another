import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/coach_note_repository.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/repositories/profile_repository.dart';
import 'package:trufit_bodamma/models/coach_note.dart';
import '../helpers/test_hive_setup.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  late ProviderContainer container;
  late CoachNoteRepository coachNoteRepo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    await setUpTestHive();
    
    coachNoteRepo = CoachNoteRepository();
    await coachNoteRepo.init();
    
    final profileRepo = ProfileRepository();
    await profileRepo.init();
    
    final dailyLogRepo = DailyLogRepository();
    await dailyLogRepo.init();

    final habitRepo = HabitRepository();
    await habitRepo.init();
    
    final mealRepo = MealRepository();
    await mealRepo.init();

    container = ProviderContainer(
      overrides: [
        coachNoteRepoProvider.overrideWithValue(coachNoteRepo),
        profileRepoProvider.overrideWithValue(profileRepo),
        dailyLogRepoProvider.overrideWithValue(dailyLogRepo),
        habitRepoProvider.overrideWithValue(habitRepo),
        mealRepoProvider.overrideWithValue(mealRepo),
        dateStringProvider.overrideWith((ref) => '2023-10-02'),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await tearDownTestHive();
  });

  test('CoachNoteNotifier uses cache hit', () async {
    final note = CoachNote(date: '2023-10-02', note: 'Cached Note', isAi: false);
    await coachNoteRepo.saveNote(note);

    final asyncValue = container.read(coachNoteProvider);
    expect(asyncValue.value?.note, 'Cached Note');
  });

  test('CoachNoteNotifier force refresh bypasses cache', () async {
    final note = CoachNote(date: '2023-10-02', note: 'Cached Note', isAi: false);
    await coachNoteRepo.saveNote(note);

    // Watch the provider to ensure it stays alive and we can listen to it
    container.listen(coachNoteProvider, (_, __) {});

    await container.read(coachNoteProvider.notifier).fetchNote(force: true);
    
    final asyncValue = container.read(coachNoteProvider);
    expect(asyncValue.value?.note, contains('Bodamma')); // Fallback note contains Bodamma when no API key
  });

  test('CoachNoteNotifier fallback without API key', () async {
    // Watch the provider to ensure it stays alive and we can listen to it
    container.listen(coachNoteProvider, (_, __) {});

    final asyncValueInitial = container.read(coachNoteProvider);
    expect(asyncValueInitial.isLoading, true); // Loading initially because no cache
    
    // Wait for the async fetch to complete
    await Future.delayed(const Duration(milliseconds: 100));
    
    final asyncValue = container.read(coachNoteProvider);
    expect(asyncValue.value?.note, contains('Bodamma'));
    expect(asyncValue.value?.isAi, false);
  });
}
