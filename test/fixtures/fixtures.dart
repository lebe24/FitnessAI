import 'package:fitness/domain/models/chat_message.dart';
import 'package:fitness/domain/models/chat_response.dart';
import 'package:fitness/domain/models/exercise.dart';
import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/models/user.dart';
import 'package:fitness/domain/models/workout_log.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/models/youtube_video.dart';

/// Central repository of typed test fixtures.
/// Every test file imports from here — no inline fixture construction.
class Fixtures {
  Fixtures._();

  // ── Users ──────────────────────────────────────────────────────────────────

  static UserEntity user({
    String id = 'user-001',
    String email = 'test@example.com',
    String name = 'Test User',
  }) =>
      UserEntity(id: id, email: email, name: name);

  // ── Exercises ──────────────────────────────────────────────────────────────

  static ExerciseEntity exercise({String id = 'ex-001'}) => ExerciseEntity(
        id: id,
        name: 'Push Up',
        primaryMuscles: const ['chest', 'triceps'],
        secondaryMuscles: const ['shoulders'],
        instructions: const ['Keep core tight', 'Full range of motion'],
        equipment: 'bodyweight',
        bodyPart: 'chest',
      );

  static ExerciseSearchResultEntity exerciseResult({String id = 'ex-001'}) =>
      ExerciseSearchResultEntity(
        id: id,
        name: 'Push Up',
        bodyPart: 'chest',
        equipment: 'bodyweight',
        gifUrl: 'https://example.com/pushup.gif',
      );

  // ── YouTube ────────────────────────────────────────────────────────────────

  static YouTubeVideoEntity video({String videoId = 'vid-001'}) =>
      YouTubeVideoEntity(
        videoId: videoId,
        title: 'Push Up Tutorial',
        description: 'Learn proper push up form',
        thumbnailUrl: 'https://img.youtube.com/thumb.jpg',
        channelTitle: 'Fitness Channel',
        publishedAt: DateTime(2024, 1, 1),
      );

  // ── Chat ───────────────────────────────────────────────────────────────────

  static ChatMessageEntity chatMessage({
    String id = 'msg-001',
    bool isFromUser = true,
  }) =>
      ChatMessageEntity(
        id: id,
        message: 'Test message',
        userId: 'user-001',
        timestamp: DateTime(2024, 6, 1),
        isFromUser: isFromUser,
      );

  static ChatResponseEntity chatResponse({bool planUpdated = false}) =>
      ChatResponseEntity(
        message: 'Here is your plan.',
        planUpdated: planUpdated,
        updatedPlanData: null,
      );

  // ── Workout plan ───────────────────────────────────────────────────────────

  static WorkoutPlanEntity workoutPlan() => WorkoutPlanEntity(
        status: 'active',
        plan: WorkoutPlanData(
          analysisSummary: 'Intermediate athlete',
          physiqueRating: 7.5,
          goal: 'Build muscle',
          focus: 'Upper body',
          trainingSplit: 'Push/Pull/Legs',
          equipment: const ['barbell', 'dumbbells'],
          weeklySplit: WeeklySplit(
            days: [
              WorkoutDay(
                day: 'Monday',
                focus: 'Push',
                exercises: [
                  Exercise(name: 'Bench Press', sets: 4, reps: '8-10'),
                ],
              ),
            ],
          ),
          trainingGuidelines: const TrainingGuidelines(
            restBetweenSets: '90s',
            progressiveOverload: 'Add 2.5 kg per week',
            durationWeeks: '12 weeks',
          ),
          nutritionGuidelines: const NutritionGuidelines(
            proteinPerKg: '2g/kg',
            calorieSurplus: '300 kcal',
            hydration: '3L/day',
            sleep: '8 hours',
          ),
          extraTips: const ['Stay consistent'],
        ),
      );

  static StoredFitnessPlanEntity storedPlan({
    String id = 'plan-001',
    String? imagePath = '/images/plan.jpg',
  }) {
    final now = DateTime(2024, 6, 1);
    return StoredFitnessPlanEntity(
      id: id,
      workoutPlan: workoutPlan(),
      imagePath: imagePath,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      cloudId: null,
    );
  }

  // ── Workout logs ───────────────────────────────────────────────────────────

  static final kDate = DateTime(2025, 6, 15);

  static WorkoutSessionEntity session({
    String id = 'sess-001',
    bool isCompleted = false,
    List<ExerciseLogEntity> exerciseLogs = const [],
  }) =>
      WorkoutSessionEntity(
        id: id,
        sessionDate: kDate,
        dayLabel: 'Day 1 – Push',
        isCompleted: isCompleted,
        durationMins: isCompleted ? 45 : null,
        exerciseLogs: exerciseLogs,
      );

  static ExerciseLogEntity exerciseLog({String id = 'log-001'}) =>
      ExerciseLogEntity(
        id: id,
        sessionId: 'sess-001',
        exerciseName: 'Bench Press',
        muscleGroup: 'chest',
        orderIndex: 0,
        sets: const [
          SetEntry(setNumber: 1, reps: 10, weightKg: 60),
          SetEntry(setNumber: 2, reps: 8, weightKg: 65),
        ],
      );
}
