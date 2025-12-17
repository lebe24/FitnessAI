import 'package:fitness/app/api/domain/entities/exercise_entity.dart';
import 'package:fitness/app/chat/domain/entities/chat_message_entity.dart';
import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/ui/auth/domain/entities/user_entity.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';

/// Test fixtures and helpers for unit tests

class TestFixtures {
  static UserEntity getTestUser() {
    return UserEntity(
      id: 'test-user-id',
      email: 'test@example.com',
      name: 'Test User',
      avatarUrl: 'https://example.com/avatar.jpg',
    );
  }

  static ExerciseEntity getTestExercise() {
    return ExerciseEntity(
      id: 'exercise-1',
      name: 'Push Up',
      description: 'A basic push up exercise',
      primaryMuscles: ['chest', 'triceps'],
      secondaryMuscles: ['shoulders'],
      instructions: ['Start in plank position', 'Lower body', 'Push back up'],
      equipment: 'bodyweight',
      bodyPart: 'chest',
      gifUrl: 'https://example.com/pushup.gif',
      imageUrl: 'https://example.com/pushup.jpg',
    );
  }

  static ExerciseSearchResultEntity getTestExerciseSearchResult() {
    return ExerciseSearchResultEntity(
      id: 'exercise-1',
      name: 'Push Up',
      bodyPart: 'chest',
      equipment: 'bodyweight',
      gifUrl: 'https://example.com/pushup.gif',
    );
  }

  static ChatMessageEntity getTestChatMessage({
    String? id,
    String? message,
    bool isFromUser = true,
  }) {
    return ChatMessageEntity(
      id: id ?? 'msg-1',
      message: message ?? 'Test message',
      userId: 'test-user-id',
      timestamp: DateTime.now(),
      isFromUser: isFromUser,
    );
  }

  static WorkoutPlanEntity getTestWorkoutPlan() {
    return WorkoutPlanEntity(
      plan: WorkoutPlanData(
        analysisSummary: 'Test analysis',
        physiqueRating: 7.5,
        goal: 'Build muscle',
        focus: 'Upper body',
        trainingSplit: 'Push/Pull/Legs',
        equipment: ['dumbbells', 'barbell'],
        weeklySplit: WeeklySplit(
          days: [
            WorkoutDay(
              day: 'Monday',
              focus: 'Push',
              exercises: [
                Exercise(
                  name: 'Push Up',
                  sets: 3,
                  reps: '10-12',
                  notes: 'Keep core tight',
                ),
              ],
            ),
          ],
        ),
        trainingGuidelines: TrainingGuidelines(
          restBetweenSets: '60-90 seconds',
          progressiveOverload: 'Increase weight weekly',
          durationWeeks: '12 weeks',
        ),
        nutritionGuidelines: NutritionGuidelines(
          proteinPerKg: '2g per kg',
          calorieSurplus: '300-500 calories',
          hydration: '3-4 liters daily',
          sleep: '7-9 hours',
        ),
        extraTips: ['Stay consistent', 'Track progress'],
      ),
      status: 'active',
    );
  }

  static StoredFitnessPlanEntity getTestStoredFitnessPlan() {
    return StoredFitnessPlanEntity(
      id: 'stored-plan-1',
      workoutPlan: getTestWorkoutPlan(),
      imagePath: '/path/to/image.jpg',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      cloudId: null,
    );
  }
}

