import 'package:equatable/equatable.dart';

class WorkoutPlanEntity extends Equatable {
  final WorkoutPlanData plan;
  final String status;

  const WorkoutPlanEntity({
    required this.plan,
    required this.status,
  });

  @override
  List<Object> get props => [plan, status];
}

class WorkoutPlanData extends Equatable {
  final String analysisSummary;
  final double physiqueRating;
  final String goal;
  final String focus;
  final String trainingSplit;
  final List<String> equipment;
  final WeeklySplit weeklySplit;
  final TrainingGuidelines trainingGuidelines;
  final NutritionGuidelines nutritionGuidelines;
  final List<String> extraTips;

  const WorkoutPlanData({
    required this.analysisSummary,
    required this.physiqueRating,
    required this.goal,
    required this.focus,
    required this.trainingSplit,
    required this.equipment,
    required this.weeklySplit,
    required this.trainingGuidelines,
    required this.nutritionGuidelines,
    required this.extraTips,
  });

  @override
  List<Object> get props => [
        analysisSummary,
        physiqueRating,
        goal,
        focus,
        trainingSplit,
        equipment,
        weeklySplit,
        trainingGuidelines,
        nutritionGuidelines,
        extraTips,
      ];
}

class WeeklySplit extends Equatable {
  final List<WorkoutDay> days;

  const WeeklySplit({required this.days});

  @override
  List<Object> get props => [days];
}

class WorkoutDay extends Equatable {
  final String day;
  final String focus;
  final List<Exercise> exercises;
  final String? tip;

  const WorkoutDay({
    required this.day,
    required this.focus,
    required this.exercises,
    this.tip,
  });

  @override
  List<Object?> get props => [day, focus, exercises, tip];
}

class Exercise extends Equatable {
  final String name;
  final int sets;
  final String reps;
  final String? notes;

  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.notes,
  });

  @override
  List<Object?> get props => [name, sets, reps, notes];
}

class TrainingGuidelines extends Equatable {
  final String restBetweenSets;
  final String progressiveOverload;
  final String durationWeeks;

  const TrainingGuidelines({
    required this.restBetweenSets,
    required this.progressiveOverload,
    required this.durationWeeks,
  });

  @override
  List<Object> get props => [restBetweenSets, progressiveOverload, durationWeeks];
}

class NutritionGuidelines extends Equatable {
  final String proteinPerKg;
  final String calorieSurplus;
  final String hydration;
  final String sleep;
  final String? additionalNotes;

  const NutritionGuidelines({
    required this.proteinPerKg,
    required this.calorieSurplus,
    required this.hydration,
    required this.sleep,
    this.additionalNotes,
  });

  @override
  List<Object?> get props => [
        proteinPerKg,
        calorieSurplus,
        hydration,
        sleep,
        additionalNotes,
      ];
}

