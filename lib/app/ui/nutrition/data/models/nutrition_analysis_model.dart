import 'package:fitness/app/ui/nutrition/domain/entities/nutrition_analysis_entity.dart';

class NutritionAnalysisModel extends NutritionAnalysisEntity {
  const NutritionAnalysisModel({
    required super.dishName,
    required super.identifiedIngredients,
    required super.portionEstimates,
    required super.estimatedNutrition,
    required super.macroEstimates,
    required super.micronutrientsEstimate,
    required super.dietarySafetyConstraints,
    required super.nutrientHighlights,
    required super.workoutContext,
    required super.healthinessScore,
    required super.overallRating,
    required super.notes,
    super.imageUrl,
  });

  factory NutritionAnalysisModel.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>;
    
    return NutritionAnalysisModel(
      dishName: analysis['dishName'] as String,
      identifiedIngredients: List<String>.from(analysis['identifiedIngredients'] as List),
      portionEstimates: PortionEstimatesModel.fromJson(
        analysis['portionEstimates'] as Map<String, dynamic>,
      ),
      estimatedNutrition: EstimatedNutritionModel.fromJson(
        analysis['estimatedNutrition'] as Map<String, dynamic>,
      ),
      macroEstimates: MacroEstimatesModel.fromJson(
        analysis['macroEstimates'] as Map<String, dynamic>,
      ),
      micronutrientsEstimate: MicronutrientsEstimateModel.fromJson(
        analysis['micronutrientsEstimate'] as Map<String, dynamic>,
      ),
      dietarySafetyConstraints: DietarySafetyConstraintsModel.fromJson(
        analysis['dietarySafetyConstraints'] as Map<String, dynamic>,
      ),
      nutrientHighlights: NutrientHighlightsModel.fromJson(
        analysis['nutrientHighlights'] as Map<String, dynamic>,
      ),
      workoutContext: WorkoutContextModel.fromJson(
        analysis['workoutContext'] as Map<String, dynamic>,
      ),
      healthinessScore: (analysis['healthinessScore'] as num).toDouble(),
      overallRating: analysis['overallRating'] as String,
      notes: List<String>.from(analysis['notes'] as List),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis': {
        'dishName': dishName,
        'identifiedIngredients': identifiedIngredients,
        'portionEstimates': (portionEstimates as PortionEstimatesModel).toJson(),
        'estimatedNutrition': (estimatedNutrition as EstimatedNutritionModel).toJson(),
        'macroEstimates': (macroEstimates as MacroEstimatesModel).toJson(),
        'micronutrientsEstimate': (micronutrientsEstimate as MicronutrientsEstimateModel).toJson(),
        'dietarySafetyConstraints': (dietarySafetyConstraints as DietarySafetyConstraintsModel).toJson(),
        'nutrientHighlights': (nutrientHighlights as NutrientHighlightsModel).toJson(),
        'workoutContext': (workoutContext as WorkoutContextModel).toJson(),
        'healthinessScore': healthinessScore,
        'overallRating': overallRating,
        'notes': notes,
      },
      'image_url': imageUrl,
    };
  }
}

class PortionEstimatesModel extends PortionEstimates {
  const PortionEstimatesModel({
    super.beefG,
    super.noodlesCups,
    super.broccoliCups,
    super.carrotsCups,
    super.sauceTbsp,
    super.sesameTsp,
    super.other = const {},
  });

  factory PortionEstimatesModel.fromJson(Map<String, dynamic> json) {
    final other = <String, dynamic>{};
    json.forEach((key, value) {
      if (!['beef_g', 'noodles_cups', 'broccoli_cups', 'carrots_cups', 'sauce_tbsp', 'sesame_tsp'].contains(key)) {
        other[key] = value;
      }
    });

    return PortionEstimatesModel(
      beefG: (json['beef_g'] as num?)?.toDouble(),
      noodlesCups: (json['noodles_cups'] as num?)?.toDouble(),
      broccoliCups: (json['broccoli_cups'] as num?)?.toDouble(),
      carrotsCups: (json['carrots_cups'] as num?)?.toDouble(),
      sauceTbsp: (json['sauce_tbsp'] as num?)?.toDouble(),
      sesameTsp: (json['sesame_tsp'] as num?)?.toDouble(),
      other: other,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (beefG != null) json['beef_g'] = beefG;
    if (noodlesCups != null) json['noodles_cups'] = noodlesCups;
    if (broccoliCups != null) json['broccoli_cups'] = broccoliCups;
    if (carrotsCups != null) json['carrots_cups'] = carrotsCups;
    if (sauceTbsp != null) json['sauce_tbsp'] = sauceTbsp;
    if (sesameTsp != null) json['sesame_tsp'] = sesameTsp;
    json.addAll(other);
    return json;
  }
}

class EstimatedNutritionModel extends EstimatedNutrition {
  const EstimatedNutritionModel({
    required super.caloriesKcal,
    required super.macros,
  });

  factory EstimatedNutritionModel.fromJson(Map<String, dynamic> json) {
    return EstimatedNutritionModel(
      caloriesKcal: json['calories_kcal'] as int,
      macros: MacrosModel.fromJson(json['macros'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories_kcal': caloriesKcal,
      'macros': (macros as MacrosModel).toJson(),
    };
  }
}

class MacrosModel extends Macros {
  const MacrosModel({
    required super.proteinG,
    required super.carbsG,
    required super.fatG,
    required super.fiberG,
  });

  factory MacrosModel.fromJson(Map<String, dynamic> json) {
    return MacrosModel(
      proteinG: (json['protein_g'] as num).toDouble(),
      carbsG: (json['carbs_g'] as num).toDouble(),
      fatG: (json['fat_g'] as num).toDouble(),
      fiberG: (json['fiber_g'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
    };
  }
}

class MacroEstimatesModel extends MacroEstimates {
  const MacroEstimatesModel({
    required super.protein,
    required super.carbohydrates,
    required super.fats,
    required super.fiber,
  });

  factory MacroEstimatesModel.fromJson(Map<String, dynamic> json) {
    return MacroEstimatesModel(
      protein: MacroDetailModel.fromJson(json['protein'] as Map<String, dynamic>),
      carbohydrates: MacroDetailModel.fromJson(json['carbohydrates'] as Map<String, dynamic>),
      fats: FatsModel.fromJson(json['fats'] as Map<String, dynamic>),
      fiber: FiberModel.fromJson(json['fiber'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protein': (protein as MacroDetailModel).toJson(),
      'carbohydrates': (carbohydrates as MacroDetailModel).toJson(),
      'fats': (fats as FatsModel).toJson(),
      'fiber': (fiber as FiberModel).toJson(),
    };
  }
}

class MacroDetailModel extends MacroDetail {
  const MacroDetailModel({
    required super.grams,
    required super.percentage,
    required super.calories,
    super.quality,
    super.type,
  });

  factory MacroDetailModel.fromJson(Map<String, dynamic> json) {
    return MacroDetailModel(
      grams: (json['grams'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      quality: json['quality'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'grams': grams,
      'percentage': percentage,
      'calories': calories,
    };
    if (quality != null) json['quality'] = quality;
    if (type != null) json['type'] = type;
    return json;
  }
}

class FatsModel extends Fats {
  const FatsModel({
    required super.grams,
    required super.percentage,
    required super.calories,
    super.breakdown,
  });

  factory FatsModel.fromJson(Map<String, dynamic> json) {
    return FatsModel(
      grams: (json['grams'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      breakdown: json['breakdown'] != null
          ? FatBreakdownModel.fromJson(json['breakdown'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'grams': grams,
      'percentage': percentage,
      'calories': calories,
    };
    if (breakdown != null) {
      json['breakdown'] = (breakdown as FatBreakdownModel).toJson();
    }
    return json;
  }
}

class FatBreakdownModel extends FatBreakdown {
  const FatBreakdownModel({
    required super.saturatedG,
    required super.monounsaturatedG,
    required super.polyunsaturatedG,
  });

  factory FatBreakdownModel.fromJson(Map<String, dynamic> json) {
    return FatBreakdownModel(
      saturatedG: (json['saturated_g'] as num).toDouble(),
      monounsaturatedG: (json['monounsaturated_g'] as num).toDouble(),
      polyunsaturatedG: (json['polyunsaturated_g'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saturated_g': saturatedG,
      'monounsaturated_g': monounsaturatedG,
      'polyunsaturated_g': polyunsaturatedG,
    };
  }
}

class FiberModel extends Fiber {
  const FiberModel({
    required super.grams,
    required super.percentage,
  });

  factory FiberModel.fromJson(Map<String, dynamic> json) {
    return FiberModel(
      grams: (json['grams'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grams': grams,
      'percentage': percentage,
    };
  }
}

class MicronutrientsEstimateModel extends MicronutrientsEstimate {
  const MicronutrientsEstimateModel({
    required super.vitamins,
    required super.minerals,
    required super.antioxidants,
  });

  factory MicronutrientsEstimateModel.fromJson(Map<String, dynamic> json) {
    return MicronutrientsEstimateModel(
      vitamins: VitaminsModel.fromJson(json['vitamins'] as Map<String, dynamic>),
      minerals: MineralsModel.fromJson(json['minerals'] as Map<String, dynamic>),
      antioxidants: List<String>.from(json['antioxidants'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vitamins': (vitamins as VitaminsModel).toJson(),
      'minerals': (minerals as MineralsModel).toJson(),
      'antioxidants': antioxidants,
    };
  }
}

class VitaminsModel extends Vitamins {
  const VitaminsModel({
    super.vitaminAMcg,
    super.vitaminCMg,
    super.vitaminDIu,
    super.vitaminEMg,
    super.vitaminKMcg,
    super.thiamineMg,
    super.riboflavinMg,
    super.niacinMg,
    super.vitaminB6Mg,
    super.folateMcg,
    super.vitaminB12Mcg,
  });

  factory VitaminsModel.fromJson(Map<String, dynamic> json) {
    return VitaminsModel(
      vitaminAMcg: (json['vitamin_a_mcg'] as num?)?.toDouble(),
      vitaminCMg: (json['vitamin_c_mg'] as num?)?.toDouble(),
      vitaminDIu: (json['vitamin_d_iu'] as num?)?.toDouble(),
      vitaminEMg: (json['vitamin_e_mg'] as num?)?.toDouble(),
      vitaminKMcg: (json['vitamin_k_mcg'] as num?)?.toDouble(),
      thiamineMg: (json['thiamine_mg'] as num?)?.toDouble(),
      riboflavinMg: (json['riboflavin_mg'] as num?)?.toDouble(),
      niacinMg: (json['niacin_mg'] as num?)?.toDouble(),
      vitaminB6Mg: (json['vitamin_b6_mg'] as num?)?.toDouble(),
      folateMcg: (json['folate_mcg'] as num?)?.toDouble(),
      vitaminB12Mcg: (json['vitamin_b12_mcg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (vitaminAMcg != null) json['vitamin_a_mcg'] = vitaminAMcg;
    if (vitaminCMg != null) json['vitamin_c_mg'] = vitaminCMg;
    if (vitaminDIu != null) json['vitamin_d_iu'] = vitaminDIu;
    if (vitaminEMg != null) json['vitamin_e_mg'] = vitaminEMg;
    if (vitaminKMcg != null) json['vitamin_k_mcg'] = vitaminKMcg;
    if (thiamineMg != null) json['thiamine_mg'] = thiamineMg;
    if (riboflavinMg != null) json['riboflavin_mg'] = riboflavinMg;
    if (niacinMg != null) json['niacin_mg'] = niacinMg;
    if (vitaminB6Mg != null) json['vitamin_b6_mg'] = vitaminB6Mg;
    if (folateMcg != null) json['folate_mcg'] = folateMcg;
    if (vitaminB12Mcg != null) json['vitamin_b12_mcg'] = vitaminB12Mcg;
    return json;
  }
}

class MineralsModel extends Minerals {
  const MineralsModel({
    super.calciumMg,
    super.ironMg,
    super.magnesiumMg,
    super.phosphorusMg,
    super.potassiumMg,
    super.sodiumMg,
    super.zincMg,
    super.copperMg,
    super.manganeseMg,
    super.seleniumMcg,
  });

  factory MineralsModel.fromJson(Map<String, dynamic> json) {
    return MineralsModel(
      calciumMg: (json['calcium_mg'] as num?)?.toDouble(),
      ironMg: (json['iron_mg'] as num?)?.toDouble(),
      magnesiumMg: (json['magnesium_mg'] as num?)?.toDouble(),
      phosphorusMg: (json['phosphorus_mg'] as num?)?.toDouble(),
      potassiumMg: (json['potassium_mg'] as num?)?.toDouble(),
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble(),
      zincMg: (json['zinc_mg'] as num?)?.toDouble(),
      copperMg: (json['copper_mg'] as num?)?.toDouble(),
      manganeseMg: (json['manganese_mg'] as num?)?.toDouble(),
      seleniumMcg: (json['selenium_mcg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (calciumMg != null) json['calcium_mg'] = calciumMg;
    if (ironMg != null) json['iron_mg'] = ironMg;
    if (magnesiumMg != null) json['magnesium_mg'] = magnesiumMg;
    if (phosphorusMg != null) json['phosphorus_mg'] = phosphorusMg;
    if (potassiumMg != null) json['potassium_mg'] = potassiumMg;
    if (sodiumMg != null) json['sodium_mg'] = sodiumMg;
    if (zincMg != null) json['zinc_mg'] = zincMg;
    if (copperMg != null) json['copper_mg'] = copperMg;
    if (manganeseMg != null) json['manganese_mg'] = manganeseMg;
    if (seleniumMcg != null) json['selenium_mcg'] = seleniumMcg;
    return json;
  }
}

class DietarySafetyConstraintsModel extends DietarySafetyConstraints {
  const DietarySafetyConstraintsModel({
    required super.allergens,
    required super.dietaryRestrictions,
    required super.safetyConcerns,
    required super.foodSafety,
  });

  factory DietarySafetyConstraintsModel.fromJson(Map<String, dynamic> json) {
    return DietarySafetyConstraintsModel(
      allergens: (json['allergens'] as List)
          .map((e) => AllergenModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      dietaryRestrictions: DietaryRestrictionsModel.fromJson(
        json['dietaryRestrictions'] as Map<String, dynamic>,
      ),
      safetyConcerns: (json['safetyConcerns'] as List)
          .map((e) => SafetyConcernModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      foodSafety: FoodSafetyModel.fromJson(json['foodSafety'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergens': allergens.map((e) => (e as AllergenModel).toJson()).toList(),
      'dietaryRestrictions': (dietaryRestrictions as DietaryRestrictionsModel).toJson(),
      'safetyConcerns': safetyConcerns.map((e) => (e as SafetyConcernModel).toJson()).toList(),
      'foodSafety': (foodSafety as FoodSafetyModel).toJson(),
    };
  }
}

class AllergenModel extends Allergen {
  const AllergenModel({
    required super.name,
    required super.source,
    required super.severity,
  });

  factory AllergenModel.fromJson(Map<String, dynamic> json) {
    return AllergenModel(
      name: json['name'] as String,
      source: json['source'] as String,
      severity: json['severity'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'source': source,
      'severity': severity,
    };
  }
}

class DietaryRestrictionsModel extends DietaryRestrictions {
  const DietaryRestrictionsModel({
    required super.glutenFree,
    required super.vegan,
    required super.vegetarian,
    required super.halal,
    required super.kosher,
    required super.dairyFree,
    required super.nutFree,
  });

  factory DietaryRestrictionsModel.fromJson(Map<String, dynamic> json) {
    return DietaryRestrictionsModel(
      glutenFree: json['glutenFree'] as bool,
      vegan: json['vegan'] as bool,
      vegetarian: json['vegetarian'] as bool,
      halal: json['halal'] as bool,
      kosher: json['kosher'] as bool,
      dairyFree: json['dairyFree'] as bool,
      nutFree: json['nutFree'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'glutenFree': glutenFree,
      'vegan': vegan,
      'vegetarian': vegetarian,
      'halal': halal,
      'kosher': kosher,
      'dairyFree': dairyFree,
      'nutFree': nutFree,
    };
  }
}

class SafetyConcernModel extends SafetyConcern {
  const SafetyConcernModel({
    required super.type,
    required super.severity,
    required super.message,
  });

  factory SafetyConcernModel.fromJson(Map<String, dynamic> json) {
    return SafetyConcernModel(
      type: json['type'] as String,
      severity: json['severity'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'severity': severity,
      'message': message,
    };
  }
}

class FoodSafetyModel extends FoodSafety {
  const FoodSafetyModel({
    required super.temperatureConcern,
    required super.crossContaminationRisk,
    required super.storageAdvice,
  });

  factory FoodSafetyModel.fromJson(Map<String, dynamic> json) {
    return FoodSafetyModel(
      temperatureConcern: json['temperatureConcern'] as bool,
      crossContaminationRisk: json['crossContaminationRisk'] as String,
      storageAdvice: json['storageAdvice'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperatureConcern': temperatureConcern,
      'crossContaminationRisk': crossContaminationRisk,
      'storageAdvice': storageAdvice,
    };
  }
}

class NutrientHighlightsModel extends NutrientHighlights {
  const NutrientHighlightsModel({
    required super.positive,
    required super.moderate,
    required super.allergens,
  });

  factory NutrientHighlightsModel.fromJson(Map<String, dynamic> json) {
    return NutrientHighlightsModel(
      positive: List<String>.from(json['positive'] as List),
      moderate: List<String>.from(json['moderate'] as List),
      allergens: List<String>.from(json['allergens'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'positive': positive,
      'moderate': moderate,
      'allergens': allergens,
    };
  }
}

class WorkoutContextModel extends WorkoutContext {
  const WorkoutContextModel({
    required super.postWorkoutRecommended,
    required super.why,
    required super.bestTimingHoursAfterWorkout,
    required super.ifNoWorkout,
  });

  factory WorkoutContextModel.fromJson(Map<String, dynamic> json) {
    return WorkoutContextModel(
      postWorkoutRecommended: json['postWorkoutRecommended'] as bool,
      why: List<String>.from(json['why'] as List),
      bestTimingHoursAfterWorkout: json['bestTiming_hoursAfterWorkout'] as String,
      ifNoWorkout: IfNoWorkoutModel.fromJson(json['ifNoWorkout'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postWorkoutRecommended': postWorkoutRecommended,
      'why': why,
      'bestTiming_hoursAfterWorkout': bestTimingHoursAfterWorkout,
      'ifNoWorkout': (ifNoWorkout as IfNoWorkoutModel).toJson(),
    };
  }
}

class IfNoWorkoutModel extends IfNoWorkout {
  const IfNoWorkoutModel({
    required super.suggestions,
  });

  factory IfNoWorkoutModel.fromJson(Map<String, dynamic> json) {
    return IfNoWorkoutModel(
      suggestions: List<String>.from(json['suggestions'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suggestions': suggestions,
    };
  }
}
























