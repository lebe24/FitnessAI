import 'dart:io';

import 'package:fitness/data/models/home/workout_plan_model.dart';
import 'package:fitness/data/services/workout_plan/workout_plan_remote_service.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/repositories/home_repository.dart';

/// Thrown when the backend response is structurally valid JSON but missing
/// the fields required to build a usable workout plan.
class WorkoutPlanValidationException implements Exception {
  final String message;
  const WorkoutPlanValidationException(this.message);

  @override
  String toString() => 'WorkoutPlanValidationException: $message';
}

class HomeRepositoryImpl implements HomeRepository {
  final WorkoutPlanRemoteDataSource remoteDataSource;

  HomeRepositoryImpl(this.remoteDataSource);

  /// Generate a workout plan.
  ///
  /// Responsibility split:
  ///   - [WorkoutPlanRemoteDataSource] handles HTTP transport → raw Map.
  ///   - [_validateResponse] guards required fields before model conversion.
  ///   - [WorkoutPlanModel.fromJson] converts the Map into the domain entity.
  @override
  Future<WorkoutPlanEntity> uploadImage(
    String? extrainfo,
    File image, {
    required String goal,
    required String duration,
    required String trainingSplit,
    required String gender,
    required String height,
    required String weight,
    required String experience,
  }) async {
    final raw = await remoteDataSource.generateWorkoutPlan(
      image: image,
      goal: goal,
      duration: duration,
      trainingSplit: trainingSplit,
      gender: gender,
      height: height,
      weight: weight,
      experience: experience,
      extraInfo: extrainfo,
    );

    _validateResponse(raw);

    return WorkoutPlanModel.fromJson(raw);
  }

  @override
  Future<String> getBaseInfo() => remoteDataSource.getBaseInfo();

  // ── Response safeguards ────────────────────────────────────────────────────

  /// Validates that the raw API response contains all fields required for a
  /// usable workout plan. Throws [WorkoutPlanValidationException] with a
  /// descriptive message if anything critical is missing.
  static void _validateResponse(Map<String, dynamic> raw) {
    // Top-level status check
    if (raw['status'] == 'error') {
      throw WorkoutPlanValidationException(
        raw['error']?.toString() ?? 'Server returned an error status.',
      );
    }

    // The 'plan' envelope must exist and be a Map
    final plan = raw['plan'];
    if (plan == null) {
      throw WorkoutPlanValidationException(
        "Response is missing the 'plan' field.",
      );
    }
    if (plan is! Map<String, dynamic>) {
      throw WorkoutPlanValidationException(
        "Expected 'plan' to be a JSON object, got ${plan.runtimeType}.",
      );
    }

    // Weekly schedule must be present and non-empty
    final schedule = plan['weekly_schedule'] ?? plan['weekly_split'];
    if (schedule == null) {
      throw WorkoutPlanValidationException(
        "Plan is missing a weekly schedule (weekly_schedule / weekly_split).",
      );
    }

    List<dynamic>? days;
    if (schedule is List) {
      days = schedule;
    } else if (schedule is Map) {
      days = schedule['days'] as List<dynamic>?;
    }

    if (days == null || days.isEmpty) {
      throw WorkoutPlanValidationException(
        'Workout plan contains no training days.',
      );
    }

    // Each day must have at least one exercise
    for (final day in days) {
      if (day is Map<String, dynamic>) {
        final exercises = day['exercises'];
        if (exercises is List && exercises.isEmpty) {
          final name = day['day_name'] ?? day['day'] ?? 'Unknown day';
          throw WorkoutPlanValidationException(
            "Training day '$name' has no exercises.",
          );
        }
      }
    }

    // Nutrition block must be present
    if (plan['nutrition'] == null && plan['nutrition_guidelines'] == null) {
      throw WorkoutPlanValidationException(
        "Plan is missing a nutrition section.",
      );
    }
  }
}
