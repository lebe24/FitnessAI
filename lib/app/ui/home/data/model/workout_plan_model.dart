import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';

/// Safely parses the physique rating into a double, accepting formats like:
/// - "0.7"
/// - "70"
/// - "70/100"
/// - "70%"
double _parsePhysiqueRating(dynamic value) {
  if (value == null) return 0.0;

  var s = value.toString().trim();
  if (s.isEmpty) return 0.0;

  // If format is like "70/100", use the first part
  if (s.contains('/')) {
    s = s.split('/').first;
  }

  // Remove percentage sign
  s = s.replaceAll('%', '').trim();

  // Extract the first numeric value using regex as a fallback
  final match = RegExp(r'[-+]?[0-9]*\.?[0-9]+').firstMatch(s);
  if (match != null) {
    final numberStr = match.group(0);
    final parsed = double.tryParse(numberStr ?? '');
    if (parsed != null) {
      return parsed;
    }
  }

  // Final fallback
  return double.tryParse(s) ?? 0.0;
}

class WorkoutPlanModel extends WorkoutPlanEntity {
  const WorkoutPlanModel({
    required super.plan,
    required super.status,
  });

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanModel(
      plan: WorkoutPlanDataModel.fromJson(json['plan'] as Map<String, dynamic>),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': (plan as WorkoutPlanDataModel).toJson(),
      'status': status,
    };
  }
}

class WorkoutPlanDataModel extends WorkoutPlanData {
  const WorkoutPlanDataModel({
    required super.analysisSummary,
    required super.physiqueRating,
    required super.goal,
    required super.focus,
    required super.trainingSplit,
    required super.equipment,
    required super.weeklySplit,
    required super.trainingGuidelines,
    required super.nutritionGuidelines,
    required super.extraTips,
  });

  factory WorkoutPlanDataModel.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanDataModel(
      analysisSummary: json['analysis_summary'] as String,
      physiqueRating: _parsePhysiqueRating(json['physique_rating']),
      goal: json['goal'] as String,
      focus: json['focus'] as String,
      trainingSplit: json['training_split'] as String,
      equipment: (json['equipment'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      weeklySplit: WeeklySplitModel.fromJson(
        json['weekly_split'] as Map<String, dynamic>,
      ),
      trainingGuidelines: TrainingGuidelinesModel.fromJson(
        json['training_guidelines'] as Map<String, dynamic>,
      ),
      nutritionGuidelines: NutritionGuidelinesModel.fromJson(
        json['nutrition_guidelines'] as Map<String, dynamic>,
      ),
      extraTips: (json['extra_tips'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis_summary': analysisSummary,
      'physique_rating': physiqueRating.toString(),
      'goal': goal,
      'focus': focus,
      'training_split': trainingSplit,
      'equipment': equipment,
      'weekly_split': (weeklySplit as WeeklySplitModel).toJson(),
      'training_guidelines': (trainingGuidelines as TrainingGuidelinesModel).toJson(),
      'nutrition_guidelines': (nutritionGuidelines as NutritionGuidelinesModel).toJson(),
      'extra_tips': extraTips,
    };
  }
}

class WeeklySplitModel extends WeeklySplit {
  const WeeklySplitModel({required super.days});

  factory WeeklySplitModel.fromJson(Map<String, dynamic> json) {
    return WeeklySplitModel(
      days: (json['days'] as List<dynamic>)
          .map((e) => WorkoutDayModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days.map((day) => (day as WorkoutDayModel).toJson()).toList(),
    };
  }
}

class WorkoutDayModel extends WorkoutDay {
  const WorkoutDayModel({
    required super.day,
    required super.focus,
    required super.exercises,
    super.tip,
  });

  factory WorkoutDayModel.fromJson(Map<String, dynamic> json) {
    return WorkoutDayModel(
      day: json['day'] as String,
      focus: json['focus'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      tip: json['tip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'focus': focus,
      'exercises': exercises.map((e) => (e as ExerciseModel).toJson()).toList(),
      'tip': tip,
    };
  }
}

class ExerciseModel extends Exercise {
  const ExerciseModel({
    required super.name,
    required super.sets,
    required super.reps,
    super.notes,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      name: json['name'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'notes': notes,
    };
  }
}

class TrainingGuidelinesModel extends TrainingGuidelines {
  const TrainingGuidelinesModel({
    required super.restBetweenSets,
    required super.progressiveOverload,
    required super.durationWeeks,
  });

  factory TrainingGuidelinesModel.fromJson(Map<String, dynamic> json) {
    return TrainingGuidelinesModel(
      restBetweenSets: json['rest_between_sets'] as String,
      progressiveOverload: json['progressive_overload'] as String,
      durationWeeks: json['duration_weeks'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rest_between_sets': restBetweenSets,
      'progressive_overload': progressiveOverload,
      'duration_weeks': durationWeeks,
    };
  }
}

class NutritionGuidelinesModel extends NutritionGuidelines {
  const NutritionGuidelinesModel({
    required super.proteinPerKg,
    required super.calorieSurplus,
    required super.hydration,
    required super.sleep,
    super.additionalNotes,
  });

  factory NutritionGuidelinesModel.fromJson(Map<String, dynamic> json) {
    return NutritionGuidelinesModel(
      proteinPerKg: json['protein_per_kg'] as String,
      calorieSurplus: json['calorie_surplus'] as String,
      hydration: json['hydration'] as String,
      sleep: json['sleep'] as String,
      additionalNotes: json['additional_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protein_per_kg': proteinPerKg,
      'calorie_surplus': calorieSurplus,
      'hydration': hydration,
      'sleep': sleep,
      'additional_notes': additionalNotes,
    };
  }
}

