import 'package:fitness/domain/models/workout_plan.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

double _parseRating(dynamic value) {
  if (value == null) return 0.0;
  var s = value.toString().trim();
  if (s.isEmpty) return 0.0;
  if (s.contains('/')) s = s.split('/').first;
  s = s.replaceAll('%', '').trim();
  final m = RegExp(r'[-+]?[0-9]*\.?[0-9]+').firstMatch(s);
  if (m != null) return double.tryParse(m.group(0) ?? '') ?? 0.0;
  return double.tryParse(s) ?? 0.0;
}

String _str(dynamic v, [String fallback = '']) =>
    v?.toString().isNotEmpty == true ? v.toString() : fallback;

List<String> _strList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

// ── Top-level response wrapper ─────────────────────────────────────────────────

class WorkoutPlanModel extends WorkoutPlanEntity {
  const WorkoutPlanModel({
    required super.plan,
    required super.status,
  });

  /// Parses the backend WorkoutPlanResponse envelope:
  /// { "status": "success", "plan": { ...WorkoutPlanResult... }, "note": null }
  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'] as Map<String, dynamic>? ?? json;
    return WorkoutPlanModel(
      status: _str(json['status'], 'success'),
      plan: WorkoutPlanDataModel.fromJson(planJson),
    );
  }

  /// Promotes any [WorkoutPlanEntity] to a [WorkoutPlanModel] without casting.
  /// Safe to call when the runtime type might be the plain domain entity.
  factory WorkoutPlanModel.fromEntity(WorkoutPlanEntity entity) {
    if (entity is WorkoutPlanModel) return entity;
    return WorkoutPlanModel(
      status: entity.status,
      plan: WorkoutPlanDataModel.fromData(entity.plan),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'plan': WorkoutPlanDataModel.fromData(plan).toJson(),
      };
}

// ── Plan data — maps new backend WorkoutPlanResult → existing Flutter domain ──

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
    // ── Meta ──────────────────────────────────────────────────────────────────
    final meta = json['plan_metadata'] as Map<String, dynamic>? ?? {};

    final analysisSummary = _str(
      json['physique_summary'],
      _str(json['analysis_summary'], 'No summary available.'),
    );

    final physiqueRating = meta.containsKey('physique_rating')
        ? _parseRating(meta['physique_rating'])
        : _parseRating(json['physique_rating']);

    final goal = _str(meta['goal'], _str(json['goal'], 'General Fitness'));

    final focus = _str(
      meta['training_style'],
      _str(json['focus'], 'Balanced Training'),
    );

    final trainingDays = meta['training_days_per_week']?.toString() ??
        json['training_days_per_week']?.toString() ??
        '4';
    final durationWeeks = meta['duration_weeks']?.toString() ??
        json['duration_weeks']?.toString() ??
        '8';
    final trainingSplit =
        _str(json['training_split'], '$trainingDays days/week');

    final equipment = meta.containsKey('equipment_required')
        ? _strList(meta['equipment_required'])
        : _strList(json['equipment']);

    // ── Weekly schedule ───────────────────────────────────────────────────────
    // New backend key: "weekly_schedule"; legacy key: "weekly_split"
    final WeeklySplit weeklySplit;
    if (json.containsKey('weekly_schedule')) {
      final raw = json['weekly_schedule'] as List<dynamic>? ?? [];
      weeklySplit = WeeklySplitModel(
        days: raw
            .map((d) => WorkoutDayModel.fromNewJson(d as Map<String, dynamic>))
            .toList(),
      );
    } else if (json.containsKey('weekly_split')) {
      weeklySplit = WeeklySplitModel.fromJson(
        json['weekly_split'] as Map<String, dynamic>,
      );
    } else {
      weeklySplit = const WeeklySplitModel(days: []);
    }

    // ── Training guidelines ───────────────────────────────────────────────────
    final TrainingGuidelines trainingGuidelines;
    if (json.containsKey('training_guidelines')) {
      trainingGuidelines = TrainingGuidelinesModel.fromJson(
        json['training_guidelines'] as Map<String, dynamic>,
      );
    } else {
      // Synthesize from progressive_overload + plan_metadata
      final progressions = json['progressive_overload'] as List<dynamic>? ?? [];
      final firstOverload = progressions.isNotEmpty
          ? _str((progressions.first as Map)['adjustment'])
          : 'Increase load 2.5–5% each week';

      // rest_seconds from first exercise of first day
      String restBetweenSets = '60–90 seconds';
      if (json.containsKey('weekly_schedule')) {
        final days = json['weekly_schedule'] as List<dynamic>? ?? [];
        if (days.isNotEmpty) {
          final firstDay = days.first as Map<String, dynamic>;
          final exercises = firstDay['exercises'] as List<dynamic>? ?? [];
          if (exercises.isNotEmpty) {
            final restSec =
                (exercises.first as Map<String, dynamic>)['rest_seconds'];
            if (restSec != null) {
              restBetweenSets = '$restSec seconds';
            }
          }
        }
      }

      trainingGuidelines = TrainingGuidelinesModel(
        restBetweenSets: restBetweenSets,
        progressiveOverload: firstOverload,
        durationWeeks: '$durationWeeks weeks',
      );
    }

    // ── Nutrition guidelines ──────────────────────────────────────────────────
    final NutritionGuidelines nutritionGuidelines;
    if (json.containsKey('nutrition_guidelines')) {
      nutritionGuidelines = NutritionGuidelinesModel.fromJson(
        json['nutrition_guidelines'] as Map<String, dynamic>,
      );
    } else if (json.containsKey('nutrition')) {
      final n = json['nutrition'] as Map<String, dynamic>;
      final recovery = json['recovery'] as Map<String, dynamic>? ?? {};
      nutritionGuidelines = NutritionGuidelinesModel(
        proteinPerKg: _str(n['protein_g'], '2g / kg body weight'),
        calorieSurplus: _str(n['daily_calories'], 'Maintenance ± 200 kcal'),
        hydration: _str(n['hydration'], '3–4 L / day'),
        sleep: _str(recovery['sleep_hours'], '7–9 hours'),
        additionalNotes: _str(n['meal_timing_notes']).isEmpty
            ? null
            : _str(n['meal_timing_notes']),
      );
    } else {
      nutritionGuidelines = const NutritionGuidelinesModel(
        proteinPerKg: '2g / kg body weight',
        calorieSurplus: 'Maintenance ± 200 kcal',
        hydration: '3–4 L / day',
        sleep: '7–9 hours',
      );
    }

    // ── Extra tips ────────────────────────────────────────────────────────────
    final extraTips = json.containsKey('key_principles')
        ? _strList(json['key_principles'])
        : _strList(json['extra_tips']);

    return WorkoutPlanDataModel(
      analysisSummary: analysisSummary,
      physiqueRating: physiqueRating,
      goal: goal,
      focus: focus,
      trainingSplit: trainingSplit,
      equipment: equipment,
      weeklySplit: weeklySplit,
      trainingGuidelines: trainingGuidelines,
      nutritionGuidelines: nutritionGuidelines,
      extraTips: extraTips,
    );
  }

  /// Promotes any [WorkoutPlanData] to a [WorkoutPlanDataModel] without casting.
  factory WorkoutPlanDataModel.fromData(WorkoutPlanData data) {
    if (data is WorkoutPlanDataModel) return data;
    return WorkoutPlanDataModel(
      analysisSummary:    data.analysisSummary,
      physiqueRating:     data.physiqueRating,
      goal:               data.goal,
      focus:              data.focus,
      trainingSplit:      data.trainingSplit,
      equipment:          data.equipment,
      weeklySplit:        WeeklySplitModel.fromSplit(data.weeklySplit),
      trainingGuidelines: TrainingGuidelinesModel.fromGuidelines(data.trainingGuidelines),
      nutritionGuidelines: NutritionGuidelinesModel.fromGuidelines(data.nutritionGuidelines),
      extraTips:          data.extraTips,
    );
  }

  Map<String, dynamic> toJson() => {
        'analysis_summary': analysisSummary,
        'physique_rating': physiqueRating.toString(),
        'goal': goal,
        'focus': focus,
        'training_split': trainingSplit,
        'equipment': equipment,
        'weekly_split': WeeklySplitModel.fromSplit(weeklySplit).toJson(),
        'training_guidelines':
            TrainingGuidelinesModel.fromGuidelines(trainingGuidelines).toJson(),
        'nutrition_guidelines':
            NutritionGuidelinesModel.fromGuidelines(nutritionGuidelines).toJson(),
        'extra_tips': extraTips,
      };
}

// ── Weekly split ───────────────────────────────────────────────────────────────

class WeeklySplitModel extends WeeklySplit {
  const WeeklySplitModel({required super.days});

  factory WeeklySplitModel.fromJson(Map<String, dynamic> json) =>
      WeeklySplitModel(
        days: (json['days'] as List<dynamic>)
            .map((d) => WorkoutDayModel.fromJson(d as Map<String, dynamic>))
            .toList(),
      );

  factory WeeklySplitModel.fromSplit(WeeklySplit split) {
    if (split is WeeklySplitModel) return split;
    return WeeklySplitModel(
      days: split.days.map(WorkoutDayModel.fromDay).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'days': days.map((d) => WorkoutDayModel.fromDay(d).toJson()).toList(),
      };
}

// ── Workout day ────────────────────────────────────────────────────────────────

class WorkoutDayModel extends WorkoutDay {
  const WorkoutDayModel({
    required super.day,
    required super.focus,
    required super.exercises,
    super.tip,
  });

  /// Legacy format: { day, focus, exercises, tip? }
  factory WorkoutDayModel.fromJson(Map<String, dynamic> json) =>
      WorkoutDayModel(
        day: _str(json['day'], 'Day'),
        focus: _str(json['focus'], ''),
        exercises: (json['exercises'] as List<dynamic>)
            .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        tip: json['tip'] as String?,
      );

  factory WorkoutDayModel.fromDay(WorkoutDay day) {
    if (day is WorkoutDayModel) return day;
    return WorkoutDayModel(
      day: day.day,
      focus: day.focus,
      exercises: day.exercises.map(ExerciseModel.fromExercise).toList(),
      tip: day.tip,
    );
  }

  /// New backend format: { day_name, focus, exercises (ExerciseDetail), day_tip? }
  factory WorkoutDayModel.fromNewJson(Map<String, dynamic> json) =>
      WorkoutDayModel(
        day: _str(json['day_name'], 'Day ${json['day_number'] ?? ''}'),
        focus: _str(json['focus'], ''),
        exercises: ((json['exercises'] as List<dynamic>?) ?? [])
            .map((e) =>
                ExerciseModel.fromNewJson(e as Map<String, dynamic>))
            .toList(),
        tip: json['day_tip'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'focus': focus,
        'exercises': exercises.map(ExerciseModel.fromExercise).map((e) => e.toJson()).toList(),
        'tip': tip,
      };
}

// ── Exercise ───────────────────────────────────────────────────────────────────

class ExerciseModel extends Exercise {
  const ExerciseModel({
    required super.name,
    required super.sets,
    required super.reps,
    super.notes,
  });

  /// Legacy format: { name, sets, reps, notes? }
  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
        name: _str(json['name'], 'Exercise'),
        sets: (json['sets'] as num?)?.toInt() ?? 3,
        reps: _str(json['reps'], '10'),
        notes: json['notes'] as String?,
      );

  static ExerciseModel fromExercise(Exercise ex) {
    if (ex is ExerciseModel) return ex;
    return ExerciseModel(name: ex.name, sets: ex.sets, reps: ex.reps, notes: ex.notes);
  }

  /// New backend ExerciseDetail: { name, sets, reps, rest_seconds, tempo,
  ///   muscle_targets, technique_notes, alternatives }
  factory ExerciseModel.fromNewJson(Map<String, dynamic> json) {
    final muscleTargets = _strList(json['muscle_targets']);
    final techniqueNotes = _str(json['technique_notes']);

    // Build a human-readable notes string combining muscle targets + technique
    final noteParts = <String>[];
    if (muscleTargets.isNotEmpty) noteParts.add(muscleTargets.join(', '));
    if (techniqueNotes.isNotEmpty) noteParts.add(techniqueNotes);
    final notes = noteParts.isEmpty ? null : noteParts.join(' | ');

    return ExerciseModel(
      name: _str(json['name'], 'Exercise'),
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      reps: _str(json['reps'], '10'),
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'notes': notes,
      };
}

// ── Training guidelines ────────────────────────────────────────────────────────

class TrainingGuidelinesModel extends TrainingGuidelines {
  const TrainingGuidelinesModel({
    required super.restBetweenSets,
    required super.progressiveOverload,
    required super.durationWeeks,
  });

  factory TrainingGuidelinesModel.fromGuidelines(TrainingGuidelines g) {
    if (g is TrainingGuidelinesModel) return g;
    return TrainingGuidelinesModel(
      restBetweenSets: g.restBetweenSets,
      progressiveOverload: g.progressiveOverload,
      durationWeeks: g.durationWeeks,
    );
  }

  factory TrainingGuidelinesModel.fromJson(Map<String, dynamic> json) =>
      TrainingGuidelinesModel(
        restBetweenSets: _str(json['rest_between_sets'], '60–90 seconds'),
        progressiveOverload:
            _str(json['progressive_overload'], 'Increase load each week'),
        durationWeeks: _str(json['duration_weeks'], '8 weeks'),
      );

  Map<String, dynamic> toJson() => {
        'rest_between_sets': restBetweenSets,
        'progressive_overload': progressiveOverload,
        'duration_weeks': durationWeeks,
      };
}

// ── Nutrition guidelines ───────────────────────────────────────────────────────

class NutritionGuidelinesModel extends NutritionGuidelines {
  const NutritionGuidelinesModel({
    required super.proteinPerKg,
    required super.calorieSurplus,
    required super.hydration,
    required super.sleep,
    super.additionalNotes,
  });

  factory NutritionGuidelinesModel.fromGuidelines(NutritionGuidelines g) {
    if (g is NutritionGuidelinesModel) return g;
    return NutritionGuidelinesModel(
      proteinPerKg: g.proteinPerKg,
      calorieSurplus: g.calorieSurplus,
      hydration: g.hydration,
      sleep: g.sleep,
      additionalNotes: g.additionalNotes,
    );
  }

  factory NutritionGuidelinesModel.fromJson(Map<String, dynamic> json) =>
      NutritionGuidelinesModel(
        proteinPerKg: _str(json['protein_per_kg'], '2g / kg'),
        calorieSurplus: _str(json['calorie_surplus'], 'Maintenance ± 200 kcal'),
        hydration: _str(json['hydration'], '3–4 L / day'),
        sleep: _str(json['sleep'], '7–9 hours'),
        additionalNotes: json['additional_notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'protein_per_kg': proteinPerKg,
        'calorie_surplus': calorieSurplus,
        'hydration': hydration,
        'sleep': sleep,
        'additional_notes': additionalNotes,
      };
}
