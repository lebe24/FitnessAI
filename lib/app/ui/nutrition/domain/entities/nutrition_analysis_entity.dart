import 'package:equatable/equatable.dart';

class NutritionAnalysisEntity extends Equatable {
  final String dishName;
  final List<String> identifiedIngredients;
  final PortionEstimates portionEstimates;
  final EstimatedNutrition estimatedNutrition;
  final MacroEstimates macroEstimates;
  final MicronutrientsEstimate micronutrientsEstimate;
  final DietarySafetyConstraints dietarySafetyConstraints;
  final NutrientHighlights nutrientHighlights;
  final WorkoutContext workoutContext;
  final double healthinessScore;
  final String overallRating;
  final List<String> notes;
  final String? imageUrl;

  const NutritionAnalysisEntity({
    required this.dishName,
    required this.identifiedIngredients,
    required this.portionEstimates,
    required this.estimatedNutrition,
    required this.macroEstimates,
    required this.micronutrientsEstimate,
    required this.dietarySafetyConstraints,
    required this.nutrientHighlights,
    required this.workoutContext,
    required this.healthinessScore,
    required this.overallRating,
    required this.notes,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
        dishName,
        identifiedIngredients,
        portionEstimates,
        estimatedNutrition,
        macroEstimates,
        micronutrientsEstimate,
        dietarySafetyConstraints,
        nutrientHighlights,
        workoutContext,
        healthinessScore,
        overallRating,
        notes,
        imageUrl,
      ];
}

class PortionEstimates extends Equatable {
  final double? beefG;
  final double? noodlesCups;
  final double? broccoliCups;
  final double? carrotsCups;
  final double? sauceTbsp;
  final double? sesameTsp;
  final Map<String, dynamic> other;

  const PortionEstimates({
    this.beefG,
    this.noodlesCups,
    this.broccoliCups,
    this.carrotsCups,
    this.sauceTbsp,
    this.sesameTsp,
    this.other = const {},
  });

  @override
  List<Object?> get props => [
        beefG,
        noodlesCups,
        broccoliCups,
        carrotsCups,
        sauceTbsp,
        sesameTsp,
        other,
      ];
}

class EstimatedNutrition extends Equatable {
  final int caloriesKcal;
  final Macros macros;

  const EstimatedNutrition({
    required this.caloriesKcal,
    required this.macros,
  });

  @override
  List<Object?> get props => [caloriesKcal, macros];
}

class Macros extends Equatable {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const Macros({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
  });

  @override
  List<Object?> get props => [proteinG, carbsG, fatG, fiberG];
}

class MacroEstimates extends Equatable {
  final MacroDetail protein;
  final MacroDetail carbohydrates;
  final Fats fats;
  final Fiber fiber;

  const MacroEstimates({
    required this.protein,
    required this.carbohydrates,
    required this.fats,
    required this.fiber,
  });

  @override
  List<Object?> get props => [protein, carbohydrates, fats, fiber];
}

class MacroDetail extends Equatable {
  final double grams;
  final double percentage;
  final double calories;
  final String? quality;
  final String? type;

  const MacroDetail({
    required this.grams,
    required this.percentage,
    required this.calories,
    this.quality,
    this.type,
  });

  @override
  List<Object?> get props => [grams, percentage, calories, quality, type];
}

class Fats extends Equatable {
  final double grams;
  final double percentage;
  final double calories;
  final FatBreakdown? breakdown;

  const Fats({
    required this.grams,
    required this.percentage,
    required this.calories,
    this.breakdown,
  });

  @override
  List<Object?> get props => [grams, percentage, calories, breakdown];
}

class FatBreakdown extends Equatable {
  final double saturatedG;
  final double monounsaturatedG;
  final double polyunsaturatedG;

  const FatBreakdown({
    required this.saturatedG,
    required this.monounsaturatedG,
    required this.polyunsaturatedG,
  });

  @override
  List<Object?> get props => [saturatedG, monounsaturatedG, polyunsaturatedG];
}

class Fiber extends Equatable {
  final double grams;
  final double percentage;

  const Fiber({
    required this.grams,
    required this.percentage,
  });

  @override
  List<Object?> get props => [grams, percentage];
}

class MicronutrientsEstimate extends Equatable {
  final Vitamins vitamins;
  final Minerals minerals;
  final List<String> antioxidants;

  const MicronutrientsEstimate({
    required this.vitamins,
    required this.minerals,
    required this.antioxidants,
  });

  @override
  List<Object?> get props => [vitamins, minerals, antioxidants];
}

class Vitamins extends Equatable {
  final double? vitaminAMcg;
  final double? vitaminCMg;
  final double? vitaminDIu;
  final double? vitaminEMg;
  final double? vitaminKMcg;
  final double? thiamineMg;
  final double? riboflavinMg;
  final double? niacinMg;
  final double? vitaminB6Mg;
  final double? folateMcg;
  final double? vitaminB12Mcg;

  const Vitamins({
    this.vitaminAMcg,
    this.vitaminCMg,
    this.vitaminDIu,
    this.vitaminEMg,
    this.vitaminKMcg,
    this.thiamineMg,
    this.riboflavinMg,
    this.niacinMg,
    this.vitaminB6Mg,
    this.folateMcg,
    this.vitaminB12Mcg,
  });

  @override
  List<Object?> get props => [
        vitaminAMcg,
        vitaminCMg,
        vitaminDIu,
        vitaminEMg,
        vitaminKMcg,
        thiamineMg,
        riboflavinMg,
        niacinMg,
        vitaminB6Mg,
        folateMcg,
        vitaminB12Mcg,
      ];
}

class Minerals extends Equatable {
  final double? calciumMg;
  final double? ironMg;
  final double? magnesiumMg;
  final double? phosphorusMg;
  final double? potassiumMg;
  final double? sodiumMg;
  final double? zincMg;
  final double? copperMg;
  final double? manganeseMg;
  final double? seleniumMcg;

  const Minerals({
    this.calciumMg,
    this.ironMg,
    this.magnesiumMg,
    this.phosphorusMg,
    this.potassiumMg,
    this.sodiumMg,
    this.zincMg,
    this.copperMg,
    this.manganeseMg,
    this.seleniumMcg,
  });

  @override
  List<Object?> get props => [
        calciumMg,
        ironMg,
        magnesiumMg,
        phosphorusMg,
        potassiumMg,
        sodiumMg,
        zincMg,
        copperMg,
        manganeseMg,
        seleniumMcg,
      ];
}

class DietarySafetyConstraints extends Equatable {
  final List<Allergen> allergens;
  final DietaryRestrictions dietaryRestrictions;
  final List<SafetyConcern> safetyConcerns;
  final FoodSafety foodSafety;

  const DietarySafetyConstraints({
    required this.allergens,
    required this.dietaryRestrictions,
    required this.safetyConcerns,
    required this.foodSafety,
  });

  @override
  List<Object?> get props => [allergens, dietaryRestrictions, safetyConcerns, foodSafety];
}

class Allergen extends Equatable {
  final String name;
  final String source;
  final String severity;

  const Allergen({
    required this.name,
    required this.source,
    required this.severity,
  });

  @override
  List<Object?> get props => [name, source, severity];
}

class DietaryRestrictions extends Equatable {
  final bool glutenFree;
  final bool vegan;
  final bool vegetarian;
  final bool halal;
  final bool kosher;
  final bool dairyFree;
  final bool nutFree;

  const DietaryRestrictions({
    required this.glutenFree,
    required this.vegan,
    required this.vegetarian,
    required this.halal,
    required this.kosher,
    required this.dairyFree,
    required this.nutFree,
  });

  @override
  List<Object?> get props => [
        glutenFree,
        vegan,
        vegetarian,
        halal,
        kosher,
        dairyFree,
        nutFree,
      ];
}

class SafetyConcern extends Equatable {
  final String type;
  final String severity;
  final String message;

  const SafetyConcern({
    required this.type,
    required this.severity,
    required this.message,
  });

  @override
  List<Object?> get props => [type, severity, message];
}

class FoodSafety extends Equatable {
  final bool temperatureConcern;
  final String crossContaminationRisk;
  final String storageAdvice;

  const FoodSafety({
    required this.temperatureConcern,
    required this.crossContaminationRisk,
    required this.storageAdvice,
  });

  @override
  List<Object?> get props => [temperatureConcern, crossContaminationRisk, storageAdvice];
}

class NutrientHighlights extends Equatable {
  final List<String> positive;
  final List<String> moderate;
  final List<String> allergens;

  const NutrientHighlights({
    required this.positive,
    required this.moderate,
    required this.allergens,
  });

  @override
  List<Object?> get props => [positive, moderate, allergens];
}

class WorkoutContext extends Equatable {
  final bool postWorkoutRecommended;
  final List<String> why;
  final String bestTimingHoursAfterWorkout;
  final IfNoWorkout ifNoWorkout;

  const WorkoutContext({
    required this.postWorkoutRecommended,
    required this.why,
    required this.bestTimingHoursAfterWorkout,
    required this.ifNoWorkout,
  });

  @override
  List<Object?> get props => [
        postWorkoutRecommended,
        why,
        bestTimingHoursAfterWorkout,
        ifNoWorkout,
      ];
}

class IfNoWorkout extends Equatable {
  final List<String> suggestions;

  const IfNoWorkout({
    required this.suggestions,
  });

  @override
  List<Object?> get props => [suggestions];
}











































