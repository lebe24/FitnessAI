/// The AI analysis saved on a session after the workout, read back for the
/// history. Read-only and tolerant: the stored map may be empty, partly filled
/// or written by an older build, and none of that should break a screen.
class SessionFeedback {
  final String? analysis;
  final List<String> highlights;
  final List<String> improvements;
  final String? rest;
  final String? nextSessionTip;
  final String? nutritionNow;
  final int? proteinTargetG;
  final List<String> meals;
  final String? hydration;
  final String? timingTip;

  const SessionFeedback({
    this.analysis,
    this.highlights = const [],
    this.improvements = const [],
    this.rest,
    this.nextSessionTip,
    this.nutritionNow,
    this.proteinTargetG,
    this.meals = const [],
    this.hydration,
    this.timingTip,
  });

  factory SessionFeedback.fromMap(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const SessionFeedback();
    final nutrition = json['nutrition_advice'];
    final n = nutrition is Map ? nutrition.cast<String, dynamic>() : const <String, dynamic>{};
    final protein = n['protein_target_g'];
    return SessionFeedback(
      analysis: _text(json['session_analysis']),
      highlights: _list(json['performance_highlights']),
      improvements: _list(json['areas_to_improve']),
      rest: _text(json['rest_feedback']),
      nextSessionTip: _text(json['next_session_tip']),
      nutritionNow: _text(n['immediate']),
      proteinTargetG: protein is num && protein > 0 ? protein.round() : null,
      meals: _list(n['meal_suggestions']),
      hydration: _text(n['hydration']),
      timingTip: _text(n['timing_tip']),
    );
  }

  bool get hasNutrition =>
      nutritionNow != null || proteinTargetG != null || meals.isNotEmpty || hydration != null || timingTip != null;

  /// Nothing worth a section.
  bool get isEmpty =>
      analysis == null &&
      highlights.isEmpty &&
      improvements.isEmpty &&
      rest == null &&
      nextSessionTip == null &&
      !hasNutrition;

  static String? _text(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static List<String> _list(Object? v) {
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is String && e.trim().isNotEmpty) e.trim()
    ];
  }
}
