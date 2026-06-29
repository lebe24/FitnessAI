class SessionExerciseResult {
  final String name;
  final int sets;
  final String reps;
  final String? notes;

  const SessionExerciseResult({
    required this.name,
    required this.sets,
    required this.reps,
    this.notes,
  });

  factory SessionExerciseResult.fromJson(Map<String, dynamic> j) =>
      SessionExerciseResult(
        name: j['name'] as String,
        sets: j['sets'] as int,
        reps: j['reps'] as String,
        notes: j['notes'] as String?,
      );
}

class SuggestedExerciseResult {
  final String name;
  final int sets;
  final String reps;
  final String targetMuscle;
  final String why;

  const SuggestedExerciseResult({
    required this.name,
    required this.sets,
    required this.reps,
    required this.targetMuscle,
    required this.why,
  });

  factory SuggestedExerciseResult.fromJson(Map<String, dynamic> j) =>
      SuggestedExerciseResult(
        name: j['name'] as String,
        sets: j['sets'] as int,
        reps: j['reps'] as String,
        targetMuscle: j['target_muscle'] as String,
        why: j['why'] as String,
      );
}

class EquipmentScanResult {
  final String equipmentName;
  final String equipmentCategory;
  final String confidence;
  final List<String> primaryMuscleGroups;
  final bool alignsWithSession;
  final String alignmentReason;
  final List<SessionExerciseResult> matchedSessionExercises;
  final List<SuggestedExerciseResult> suggestedExercises;

  const EquipmentScanResult({
    required this.equipmentName,
    required this.equipmentCategory,
    required this.confidence,
    required this.primaryMuscleGroups,
    required this.alignsWithSession,
    required this.alignmentReason,
    required this.matchedSessionExercises,
    required this.suggestedExercises,
  });

  factory EquipmentScanResult.fromJson(Map<String, dynamic> j) =>
      EquipmentScanResult(
        equipmentName: j['equipment_name'] as String,
        equipmentCategory: j['equipment_category'] as String,
        confidence: j['confidence'] as String,
        primaryMuscleGroups:
            (j['primary_muscle_groups'] as List).cast<String>(),
        alignsWithSession: j['aligns_with_session'] as bool,
        alignmentReason: j['alignment_reason'] as String,
        matchedSessionExercises: (j['matched_session_exercises'] as List)
            .map((e) =>
                SessionExerciseResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        suggestedExercises: (j['suggested_exercises'] as List)
            .map((e) =>
                SuggestedExerciseResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
