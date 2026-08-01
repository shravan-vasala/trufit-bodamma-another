import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/repositories/workout_repository.dart';
import '../helpers/test_hive_setup.dart';

void main() {
  late WorkoutRepository repository;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setUpTestHive();
    repository = WorkoutRepository();
    // We won't call repository.init() fully here because it requires asset loading for seed plan
    // We'll manually initialize the boxes to avoid asset dependencies in unit tests
    // Actually, we can use a mock rootBundle or just bypass seeding if we only test session logic
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  test('toggleExerciseCompletion toggles boolean state in sessions', () async {
    // Open session box manually for testing
    await repository.init().catchError((_) {}); // catch asset load error

    const date = '2023-10-01';
    const dayId = 'day_1';
    const exercise = 'Bench Press';

    var completions = repository.getExerciseCompletions(date, dayId);
    expect(completions[exercise], isNull);

    await repository.toggleExerciseCompletion(date, dayId, exercise);
    completions = repository.getExerciseCompletions(date, dayId);
    expect(completions[exercise], isTrue);

    await repository.toggleExerciseCompletion(date, dayId, exercise);
    completions = repository.getExerciseCompletions(date, dayId);
    expect(completions[exercise], isFalse);
  });

  test('isWorkoutFinished correctly reflects workout completion', () async {
    await repository.init().catchError((_) {}); // catch asset load error

    const date = '2023-10-01';
    const dayId = 'day_1';

    expect(repository.isWorkoutFinished(date, dayId), isFalse);

    await repository.finishWorkout(date, dayId);

    expect(repository.isWorkoutFinished(date, dayId), isTrue);
  });
}
