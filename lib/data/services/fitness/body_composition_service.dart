import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

// ── Domain models ─────────────────────────────────────────────────────────────

class MuscleGroupScore {
  final String development;
  final int score;
  final String notes;
  MuscleGroupScore({required this.development, required this.score, required this.notes});
  factory MuscleGroupScore.fromJson(Map<String, dynamic> j) => MuscleGroupScore(
    development: j['development'] as String? ?? 'average',
    score: (j['score'] as num?)?.toInt() ?? 5,
    notes: j['notes'] as String? ?? '',
  );
}

class UpperBodyMuscleMap {
  final MuscleGroupScore chest, back, shoulders, biceps, triceps, forearms;
  UpperBodyMuscleMap({required this.chest, required this.back, required this.shoulders,
      required this.biceps, required this.triceps, required this.forearms});
  factory UpperBodyMuscleMap.fromJson(Map<String, dynamic> j) => UpperBodyMuscleMap(
    chest:     MuscleGroupScore.fromJson(j['chest']     as Map<String, dynamic>? ?? {}),
    back:      MuscleGroupScore.fromJson(j['back']      as Map<String, dynamic>? ?? {}),
    shoulders: MuscleGroupScore.fromJson(j['shoulders'] as Map<String, dynamic>? ?? {}),
    biceps:    MuscleGroupScore.fromJson(j['biceps']    as Map<String, dynamic>? ?? {}),
    triceps:   MuscleGroupScore.fromJson(j['triceps']   as Map<String, dynamic>? ?? {}),
    forearms:  MuscleGroupScore.fromJson(j['forearms']  as Map<String, dynamic>? ?? {}),
  );
}

class CoreMuscleMap {
  final MuscleGroupScore abs, obliques, lowerBack;
  CoreMuscleMap({required this.abs, required this.obliques, required this.lowerBack});
  factory CoreMuscleMap.fromJson(Map<String, dynamic> j) => CoreMuscleMap(
    abs:       MuscleGroupScore.fromJson(j['abs']        as Map<String, dynamic>? ?? {}),
    obliques:  MuscleGroupScore.fromJson(j['obliques']   as Map<String, dynamic>? ?? {}),
    lowerBack: MuscleGroupScore.fromJson(j['lower_back'] as Map<String, dynamic>? ?? {}),
  );
}

class LowerBodyMuscleMap {
  final MuscleGroupScore quads, hamstrings, glutes, calves;
  LowerBodyMuscleMap({required this.quads, required this.hamstrings, required this.glutes, required this.calves});
  factory LowerBodyMuscleMap.fromJson(Map<String, dynamic> j) => LowerBodyMuscleMap(
    quads:      MuscleGroupScore.fromJson(j['quads']      as Map<String, dynamic>? ?? {}),
    hamstrings: MuscleGroupScore.fromJson(j['hamstrings'] as Map<String, dynamic>? ?? {}),
    glutes:     MuscleGroupScore.fromJson(j['glutes']     as Map<String, dynamic>? ?? {}),
    calves:     MuscleGroupScore.fromJson(j['calves']     as Map<String, dynamic>? ?? {}),
  );
}

class MuscleMap {
  final UpperBodyMuscleMap upperBody;
  final CoreMuscleMap core;
  final LowerBodyMuscleMap lowerBody;
  MuscleMap({required this.upperBody, required this.core, required this.lowerBody});
  factory MuscleMap.fromJson(Map<String, dynamic> j) => MuscleMap(
    upperBody: UpperBodyMuscleMap.fromJson(j['upper_body'] as Map<String, dynamic>? ?? {}),
    core:      CoreMuscleMap.fromJson(j['core']            as Map<String, dynamic>? ?? {}),
    lowerBody: LowerBodyMuscleMap.fromJson(j['lower_body'] as Map<String, dynamic>? ?? {}),
  );
}

class BodyCompositionMetrics {
  final double bodyFatPct;
  final String bodyFatCategory;
  final double muscleMassPct;
  final String leanMassNote;
  final String visceralFatRisk;
  final int? estimatedBmrKcal;
  BodyCompositionMetrics({
    required this.bodyFatPct, required this.bodyFatCategory,
    required this.muscleMassPct, required this.leanMassNote,
    required this.visceralFatRisk, this.estimatedBmrKcal,
  });
  factory BodyCompositionMetrics.fromJson(Map<String, dynamic> j) => BodyCompositionMetrics(
    bodyFatPct:       (j['estimated_body_fat_pct']   as num?)?.toDouble() ?? 0,
    bodyFatCategory:  j['body_fat_category']          as String? ?? '',
    muscleMassPct:    (j['estimated_muscle_mass_pct'] as num?)?.toDouble() ?? 0,
    leanMassNote:     j['lean_mass_note']              as String? ?? '',
    visceralFatRisk:  j['visceral_fat_risk']           as String? ?? 'low',
    estimatedBmrKcal: (j['estimated_bmr_kcal'] as num?)?.toInt(),
  );
}

class PhysiqueScores {
  final int overall, aesthetics, symmetry, muscleDevelopment, conditioning, posture;
  PhysiqueScores({required this.overall, required this.aesthetics, required this.symmetry,
      required this.muscleDevelopment, required this.conditioning, required this.posture});
  factory PhysiqueScores.fromJson(Map<String, dynamic> j) => PhysiqueScores(
    overall:           (j['overall']            as num?)?.toInt() ?? 0,
    aesthetics:        (j['aesthetics']         as num?)?.toInt() ?? 0,
    symmetry:          (j['symmetry']           as num?)?.toInt() ?? 0,
    muscleDevelopment: (j['muscle_development'] as num?)?.toInt() ?? 0,
    conditioning:      (j['conditioning']       as num?)?.toInt() ?? 0,
    posture:           (j['posture']            as num?)?.toInt() ?? 0,
  );
}

class PostureAnalysis {
  final String overall, spineAlignment, shoulderBalance, hipAlignment;
  final List<String> identifiedIssues, correctiveRecommendations;
  PostureAnalysis({required this.overall, required this.spineAlignment,
      required this.shoulderBalance, required this.hipAlignment,
      required this.identifiedIssues, required this.correctiveRecommendations});
  factory PostureAnalysis.fromJson(Map<String, dynamic> j) => PostureAnalysis(
    overall:                   j['overall']                     as String? ?? '',
    spineAlignment:            j['spine_alignment']             as String? ?? '',
    shoulderBalance:           j['shoulder_balance']            as String? ?? '',
    hipAlignment:              j['hip_alignment']               as String? ?? '',
    identifiedIssues:          List<String>.from(j['identified_issues']          as List? ?? []),
    correctiveRecommendations: List<String>.from(j['corrective_recommendations'] as List? ?? []),
  );
}

class SymmetryAnalysis {
  final String bilateralBalance, upperLowerBalance, anteriorPosteriorBalance;
  final List<String> notableImbalances;
  SymmetryAnalysis({required this.bilateralBalance, required this.upperLowerBalance,
      required this.anteriorPosteriorBalance, required this.notableImbalances});
  factory SymmetryAnalysis.fromJson(Map<String, dynamic> j) => SymmetryAnalysis(
    bilateralBalance:          j['bilateral_balance']           as String? ?? '',
    upperLowerBalance:         j['upper_lower_balance']         as String? ?? '',
    anteriorPosteriorBalance:  j['anterior_posterior_balance']  as String? ?? '',
    notableImbalances:         List<String>.from(j['notable_imbalances'] as List? ?? []),
  );
}

class FatDistribution {
  final List<String> primaryStorageAreas;
  final String pattern, visceralRisk;
  final bool subcutaneousVisible;
  FatDistribution({required this.primaryStorageAreas, required this.pattern,
      required this.visceralRisk, required this.subcutaneousVisible});
  factory FatDistribution.fromJson(Map<String, dynamic> j) => FatDistribution(
    primaryStorageAreas: List<String>.from(j['primary_storage_areas'] as List? ?? []),
    pattern:             j['pattern']              as String? ?? 'uniform',
    visceralRisk:        j['visceral_risk']        as String? ?? '',
    subcutaneousVisible: j['subcutaneous_visible'] as bool? ?? false,
  );
}

class BodyCompositionRecommendations {
  final String priorityFocus, recommendedTrainingStyle, cardioRecommendation,
      nutritionStrategy, estimatedGoalTimeline, weeklyTrainingDays;
  BodyCompositionRecommendations({required this.priorityFocus,
      required this.recommendedTrainingStyle, required this.cardioRecommendation,
      required this.nutritionStrategy, required this.estimatedGoalTimeline,
      required this.weeklyTrainingDays});
  factory BodyCompositionRecommendations.fromJson(Map<String, dynamic> j) =>
      BodyCompositionRecommendations(
        priorityFocus:            j['priority_focus']             as String? ?? '',
        recommendedTrainingStyle: j['recommended_training_style'] as String? ?? '',
        cardioRecommendation:     j['cardio_recommendation']      as String? ?? '',
        nutritionStrategy:        j['nutrition_strategy']         as String? ?? '',
        estimatedGoalTimeline:    j['estimated_goal_timeline']    as String? ?? '',
        weeklyTrainingDays:       j['weekly_training_days']       as String? ?? '',
      );
}

class BodyCompositionResult {
  final String bodyType, estimatedAgeRange, genderPresented;
  final BodyCompositionMetrics composition;
  final PhysiqueScores physiqueScores;
  final MuscleMap muscleMap;
  final PostureAnalysis posture;
  final SymmetryAnalysis symmetry;
  final FatDistribution fatDistribution;
  final List<String> strengths, improvementAreas;
  final BodyCompositionRecommendations recommendations;
  final String overallSummary, disclaimer;
  final Map<String, dynamic> rawJson;

  BodyCompositionResult({
    required this.bodyType, required this.estimatedAgeRange, required this.genderPresented,
    required this.composition, required this.physiqueScores, required this.muscleMap,
    required this.posture, required this.symmetry, required this.fatDistribution,
    required this.strengths, required this.improvementAreas,
    required this.recommendations, required this.overallSummary, required this.disclaimer,
    this.rawJson = const {},
  });

  factory BodyCompositionResult.fromJson(Map<String, dynamic> j) {
    final a = j['analysis'] as Map<String, dynamic>? ?? j;
    return BodyCompositionResult(
      bodyType:         a['body_type']           as String? ?? '',
      estimatedAgeRange: a['estimated_age_range'] as String? ?? '',
      genderPresented:  a['gender_presented']    as String? ?? '',
      composition:      BodyCompositionMetrics.fromJson(a['composition']      as Map<String, dynamic>? ?? {}),
      physiqueScores:   PhysiqueScores.fromJson(a['physique_scores']          as Map<String, dynamic>? ?? {}),
      muscleMap:        MuscleMap.fromJson(a['muscle_map']                    as Map<String, dynamic>? ?? {}),
      posture:          PostureAnalysis.fromJson(a['posture']                 as Map<String, dynamic>? ?? {}),
      symmetry:         SymmetryAnalysis.fromJson(a['symmetry']               as Map<String, dynamic>? ?? {}),
      fatDistribution:  FatDistribution.fromJson(a['fat_distribution']        as Map<String, dynamic>? ?? {}),
      strengths:        List<String>.from(a['strengths']         as List? ?? []),
      improvementAreas: List<String>.from(a['improvement_areas'] as List? ?? []),
      recommendations:  BodyCompositionRecommendations.fromJson(a['recommendations'] as Map<String, dynamic>? ?? {}),
      overallSummary:   a['overall_summary'] as String? ?? '',
      disclaimer:       a['disclaimer']      as String? ?? '',
      rawJson:          j,
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class BodyCompositionService {
  late final Dio _dio;

  BodyCompositionService() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 3),
      sendTimeout: const Duration(seconds: 60),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        handler.next(options);
      },
    ));
  }

  Future<BodyCompositionResult> analyse({
    required File image,
    String gender = '',
    String age = '',
    String height = '',
    String weight = '',
    String goal = '',
    String fitnessLevel = '',
    String extraInfo = '',
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path,
          filename: image.path.split('/').last),
      'gender':        gender,
      'age':           age,
      'height':        height,
      'weight':        weight,
      'goal':          goal,
      'fitness_level': fitnessLevel,
      'extra_info':    extraInfo,
    });

    final res = await _dio.post('/api/v1/analysis/body-composition', data: formData);
    return BodyCompositionResult.fromJson(res.data as Map<String, dynamic>);
  }
}
