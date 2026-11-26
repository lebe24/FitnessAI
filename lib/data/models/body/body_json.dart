import 'package:fitness/domain/body/body_advice.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';

/// JSON for the body-tracking API and for the on-device cache. Dates travel as
/// `YYYY-MM-DD` and weights and lengths as kilograms and centimetres.
class BodyJson {
  BodyJson._();

  static String day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _date(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
  static double? _num(Object? v) => v is num ? v.toDouble() : null;

  // ── Goal ───────────────────────────────────────────────────────────────────

  static FitnessGoal goalFrom(Map<String, dynamic> j) => FitnessGoal(
        id: j['id'] as String?,
        type: GoalType.fromApi(j['goal_type'] as String?),
        startWeightKg: _num(j['start_weight_kg']),
        targetWeightKg: _num(j['target_weight_kg']),
        targetDate: _date(j['target_date']),
        weeklyRateKg: _num(j['weekly_rate_kg']),
        focusMuscles: [
          for (final m in (j['focus_muscles'] as List? ?? const []))
            if (MuscleGroup.fromApi(m as String?) != null) MuscleGroup.fromApi(m)!
        ],
        createdAt: _date(j['created_at']),
      );

  static Map<String, dynamic> goalTo(FitnessGoal g) => {
        'goal_type': g.type.api,
        if (g.startWeightKg != null) 'start_weight_kg': g.startWeightKg,
        if (g.targetWeightKg != null) 'target_weight_kg': g.targetWeightKg,
        if (g.targetDate != null) 'target_date': day(g.targetDate!),
        if (g.weeklyRateKg != null) 'weekly_rate_kg': g.weeklyRateKg,
        'focus_muscles': [for (final m in g.focusMuscles) m.api],
      };

  // ── Weight and measurements ────────────────────────────────────────────────

  static BodyWeightEntry weightFrom(Map<String, dynamic> j) => BodyWeightEntry(
        id: j['id'] as String?,
        date: DateTime.parse(j['logged_on'] as String),
        weightKg: (j['weight_kg'] as num).toDouble(),
        note: j['note'] as String?,
      );

  static Map<String, dynamic> weightTo(BodyWeightEntry e) => {
        'logged_on': day(e.date),
        'weight_kg': e.weightKg,
        if (e.note != null) 'note': e.note,
      };

  static BodyMeasurement? measurementFrom(Map<String, dynamic> j) {
    final site = MeasurementSite.fromApi(j['site'] as String?);
    if (site == null) return null; // a site this build does not know yet
    return BodyMeasurement(
      id: j['id'] as String?,
      date: DateTime.parse(j['measured_on'] as String),
      site: site,
      valueCm: (j['value_cm'] as num).toDouble(),
    );
  }

  static Map<String, dynamic> measurementTo(BodyMeasurement m) => {
        'measured_on': day(m.date),
        'site': m.site.api,
        'value_cm': m.valueCm,
      };

  // ── Advice ─────────────────────────────────────────────────────────────────

  static Map<String, dynamic> adviceRequestTo(AdviceRequest r) => {
        'training': {
          'sessions_logged': r.sessionsLogged,
          'workouts_per_week': r.workoutsPerWeek,
          'volume_last_28_days_kg': r.volumeLast28DaysKg,
          'streak_days': r.streakDays,
        },
        'muscles': [
          for (final m in r.muscles)
            {
              'name': m.group.api,
              'score': m.score,
              'status': m.level.name,
              'weekly_sets': m.weeklySets,
              if (m.strengthTrendPct != null) 'strength_trend_pct': m.strengthTrendPct,
            }
        ],
        'force_refresh': r.forceRefresh,
      };

  static String statusApi(ProgressStatus s) => switch (s) {
        ProgressStatus.noGoal => 'no_goal',
        ProgressStatus.notEnoughData => 'not_enough_data',
        ProgressStatus.behind => 'behind',
        ProgressStatus.onTrack => 'on_track',
        ProgressStatus.ahead => 'ahead',
        ProgressStatus.tooFast => 'too_fast',
      };

  static Map<String, dynamic> adviceTo(BodyAdvice a) => {
        'status': statusApi(a.status),
        'headline': a.headline,
        'summary': a.summary,
        'actions': [for (final x in a.actions) {'title': x.title, 'detail': x.detail}],
        'numbers': {
          'current_weight_kg': a.currentWeightKg,
          'target_weight_kg': a.targetWeightKg,
          'weekly_change_kg': a.weeklyChangeKg,
          'planned_rate_kg': a.plannedRateKg,
          'projected_weeks': a.projectedWeeks,
          'calorie_adjustment_kcal': a.calorieAdjustmentKcal,
        },
        'disclaimer': a.disclaimer,
        'generated_at': a.generatedAt.toIso8601String(),
        'source': a.fromModel ? 'model' : 'template',
        'cached': a.cached,
      };

  static BodyAdvice adviceFrom(Map<String, dynamic> j) {
    final n = (j['numbers'] as Map?)?.cast<String, dynamic>() ?? const {};
    return BodyAdvice(
      status: switch (j['status']) {
        'no_goal' => ProgressStatus.noGoal,
        'behind' => ProgressStatus.behind,
        'on_track' => ProgressStatus.onTrack,
        'ahead' => ProgressStatus.ahead,
        'too_fast' => ProgressStatus.tooFast,
        _ => ProgressStatus.notEnoughData,
      },
      headline: j['headline'] as String? ?? '',
      summary: j['summary'] as String? ?? '',
      actions: [
        for (final a in (j['actions'] as List? ?? const []))
          AdviceAction(
            title: (a as Map)['title'] as String? ?? '',
            detail: a['detail'] as String? ?? '',
          )
      ],
      currentWeightKg: _num(n['current_weight_kg']),
      targetWeightKg: _num(n['target_weight_kg']),
      weeklyChangeKg: _num(n['weekly_change_kg']),
      plannedRateKg: _num(n['planned_rate_kg']),
      projectedWeeks: _num(n['projected_weeks']),
      calorieAdjustmentKcal: (n['calorie_adjustment_kcal'] as num?)?.toInt(),
      disclaimer: j['disclaimer'] as String? ?? '',
      generatedAt: _date(j['generated_at']) ?? DateTime.now(),
      fromModel: j['source'] != 'template',
      cached: j['cached'] == true,
    );
  }

  // ── The on-device cache ────────────────────────────────────────────────────

  static Map<String, dynamic> snapshotTo(BodySnapshot s) => {
        if (s.goal != null) 'goal': {...goalTo(s.goal!), if (s.goal!.id != null) 'id': s.goal!.id},
        'weights': [for (final w in s.weights) {...weightTo(w), if (w.id != null) 'id': w.id}],
        'measurements': [for (final m in s.measurements) {...measurementTo(m), if (m.id != null) 'id': m.id}],
        'pending_weights': [for (final w in s.pendingWeights) weightTo(w)],
        'pending_measurements': [for (final m in s.pendingMeasurements) measurementTo(m)],
        'goal_pending': s.goalPending,
        'legacy_seeded': s.legacySeeded,
        if (s.ownerId != null) 'owner_id': s.ownerId,
      };

  static BodySnapshot snapshotFrom(Map<String, dynamic> j) {
    List<Map<String, dynamic>> list(String key) =>
        [for (final e in (j[key] as List? ?? const [])) Map<String, dynamic>.from(e as Map)];
    return BodySnapshot(
      goal: j['goal'] is Map ? goalFrom(Map<String, dynamic>.from(j['goal'] as Map)) : null,
      weights: list('weights').map(weightFrom).toList(),
      measurements: [for (final m in list('measurements')) if (measurementFrom(m) != null) measurementFrom(m)!],
      pendingWeights: list('pending_weights').map(weightFrom).toList(),
      pendingMeasurements: [
        for (final m in list('pending_measurements')) if (measurementFrom(m) != null) measurementFrom(m)!
      ],
      goalPending: j['goal_pending'] == true,
      legacySeeded: j['legacy_seeded'] == true,
      ownerId: j['owner_id'] as String?,
    );
  }
}
