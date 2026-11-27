import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/analytics/exercise_analytics.dart';
import 'package:fitness/data/services/coach/checkin_store.dart';
import 'package:fitness/data/services/coach/exercise_coach_service.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/coach/exercise_catalog.dart';
import 'package:fitness/domain/coach/exercise_recommendation.dart';
import 'package:fitness/domain/coach/history_line.dart';
import 'package:fitness/domain/coach/session_load.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// The coach on one exercise page.
///
/// The recommendation and the session verdict are worked out on the phone as
/// soon as the page opens. The model is only called when the person asks for
/// something, and what it says is kept for the rest of the visit.
class ExerciseCoachViewModel extends ChangeNotifier {
  final Exercise exercise;
  final Future<List<WorkoutSessionModel>?> Function() _sessions;
  final Future<FitnessGoal?> Function() _bodyGoal;
  final Future<OnboardingData?> Function() _profile;
  final ExerciseCoach _coach;
  final CheckInStore _checkIns;
  final bool Function() _allowed;
  final DateTime Function() _now;
  final ExerciseAnalytics? _analytics;

  ExerciseCoachViewModel({
    required this.exercise,
    required List<Exercise> today,
    required Future<List<WorkoutSessionModel>?> Function() sessions,
    required Future<FitnessGoal?> Function() bodyGoal,
    required Future<OnboardingData?> Function() profile,
    required ExerciseCoach coach,
    required CheckInStore checkIns,
    required bool Function() allowed,
    DateTime Function()? now,
    ExerciseAnalytics? analytics,
  })  : _today = today.isEmpty ? [exercise] : List.of(today),
        _sessions = sessions,
        _bodyGoal = bodyGoal,
        _profile = profile,
        _coach = coach,
        _checkIns = checkIns,
        _allowed = allowed,
        _now = now ?? DateTime.now,
        _analytics = analytics;

  List<Exercise> _today;
  List<WorkoutSessionModel> _logged = const [];
  GoalKind _goal = GoalKind.general;
  GoalType? _volumeGoal;
  Set<MuscleGroup> _focus = const {};
  OnboardingData? _person;
  ExerciseHistory _history = ExerciseHistory.empty;

  bool _loading = false;
  bool _unavailable = false;
  bool _disposed = false;
  Soreness? _soreness;
  ExerciseRecommendation? _recommendation;
  SessionLoad? _load;
  List<Suggestion> _candidates = const [];
  CoachAsk? _busy;
  CoachAnswer? _why;
  List<Suggestion>? _suggestions;
  List<Suggestion>? _workout;
  CoachAnswer? _lastAnswer;

  bool get allowed => _allowed();
  bool get loading => _loading;

  /// The logs could not be read, so no advice is given rather than advice from
  /// nothing.
  bool get unavailable => _unavailable;
  Soreness? get soreness => _soreness;
  ExerciseRecommendation? get recommendation => _recommendation;
  SessionLoad? get session => _load;
  List<Exercise> get today => _today;
  CoachAsk? get busy => _busy;

  /// The written explanation, once asked for.
  CoachAnswer? get why => _why;
  List<Suggestion>? get suggestions => _suggestions;
  List<Suggestion>? get workout => _workout;

  /// The latest reply, whatever was asked.
  CoachAnswer? get lastAnswer => _lastAnswer;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void>? _inFlight;

  /// Reads the logs, the goal and today's check-in. Does nothing, and reads
  /// nothing, without Pro. A call made while one is running waits for it.
  Future<void> load() {
    if (!_allowed()) return Future.value();
    return _inFlight ??= _read().whenComplete(() => _inFlight = null);
  }

  Future<void> _read() async {
    _loading = true;
    _unavailable = false;
    // Started from initState, which runs inside a build.
    await Future<void>.value();
    _notify();

    final sessions = await _safe(_sessions);
    if (sessions == null) {
      _unavailable = true;
      _loading = false;
      _notify();
      return;
    }
    _logged = sessions;
    final body = await _safe(_bodyGoal);
    _person = await _safe(_profile);
    _soreness = await _checkIns.read(_now());

    _volumeGoal = body?.type ?? _goalTypeFor(_person?.goal);
    _goal = body != null ? goalKindForBodyGoal(body.type) : _goalKindFor(_person?.goal);
    _focus = body?.focusMuscles.toSet() ?? const {};
    _history = ExerciseHistory.fromSessions(_logged, exercise.name, limit: 40);
    _recompute();
    _loading = false;
    _notify();
  }

  static Future<T?> _safe<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } catch (_) {
      return null;
    }
  }

  /// The onboarding goals are named, so they are read by name: the free-text
  /// matcher would take "Maintain Gains" for muscle building.
  static GoalKind _goalKindFor(String? goal) => switch (goal) {
        'Lose Weight' => GoalKind.fatLoss,
        'Build Muscle' || 'Build Aesthetics' => GoalKind.hypertrophy,
        'Maintain Gains' => GoalKind.general,
        null => GoalKind.general,
        _ => goalKindOf(goal),
      };

  static GoalType? _goalTypeFor(String? goal) => switch (goal) {
        'Lose Weight' => GoalType.loseWeight,
        'Build Muscle' || 'Build Aesthetics' => GoalType.buildMuscle,
        'Maintain Gains' => GoalType.maintain,
        _ => null,
      };

  bool get _beginner => _person?.experience == 'Beginner';

  void _recompute() {
    final now = _now();
    final days = _person?.workoutDays;
    final adherence = days == null || days <= 0
        ? 1.0
        : (ProgressionEngine.sessionsInWindow(_logged, now) / (days * ProgressionEngine.windowWeeks))
            .clamp(0.0, 1.0);
    _recommendation = ExerciseRecommendation.of(
      exercise: exercise,
      history: _history,
      goal: _goal,
      now: now,
      beginner: _beginner,
      trainsFocus: ProgressionEngine.trainsAny(exercise.name, _focus),
      adherence: adherence,
    );
    _load = SessionLoad.analyse(
      today: _today,
      sessions: _logged,
      now: now,
      goal: _volumeGoal,
      soreness: _soreness,
    );
    _candidates = ExerciseSuggester.candidates(
      today: _today,
      load: _load!,
      goal: _goal,
      beginner: _beginner,
      historyOf: (name) => ExerciseHistory.fromSessions(_logged, name, limit: 1),
    );
  }

  /// Answers, or clears, today's "how do you feel?". Suggestions made under a
  /// different answer are dropped.
  Future<void> setSoreness(Soreness? answer) async {
    if (!_allowed() || _recommendation == null) return;
    _soreness = answer;
    _suggestions = null;
    _workout = null;
    _why = null;
    _lastAnswer = null;
    _recompute();
    _notify();
    if (answer != null) _analytics?.checkInAnswered();
    await _checkIns.save(_now(), answer);
  }

  Future<void> askWhy() => _ask(CoachAsk.why);
  Future<void> suggest() => _ask(CoachAsk.suggest);
  Future<void> generateWorkout() => _ask(CoachAsk.workout);

  Future<void> _ask(CoachAsk ask) async {
    final rec = _recommendation, load = _load;
    if (!_allowed() || _busy != null || rec == null || load == null) return;
    _busy = ask;
    _notify();
    _analytics?.coachAsked(ask.name);

    final date = DateFormat('MMM d', 'en_US');
    final request = ExerciseCoachRequest(
      ask: ask,
      goal: _goal,
      experience: _person?.experience,
      exercise: exercise,
      recommendation: rec,
      history: [for (final h in _history.entries.take(5)) '${date.format(h.date)}: ${historyLine(h)}'],
      today: _today,
      load: load,
      candidates: _candidates,
    );
    final answer = await _coach.ask(request);

    _busy = null;
    // The check-in or the session may have changed while waiting.
    if (_disposed || !identical(load, _load)) {
      _notify();
      return;
    }
    _lastAnswer = answer;
    switch (ask) {
      case CoachAsk.why:
        _why = answer;
      case CoachAsk.suggest:
        _suggestions = answer.picks;
        _workout = null;
      case CoachAsk.workout:
        _workout = answer.picks;
        _suggestions = null;
    }
    if (answer.error != null) {
      _analytics?.coachFailed(ask.name, answer.error!.name);
    } else {
      _analytics?.coachReceived(ask.name,
          fromModel: answer.fromModel, verdict: load.verdict.name, suggestions: answer.picks.length);
    }
    _notify();
  }

  /// The recommended numbers, or the alternative, were taken.
  void used({required bool alternative}) => _analytics?.coachUsed(alternative: alternative);

  /// [added] joined today's session: recount, and drop them from what is on
  /// offer.
  void addedToSession(List<Exercise> added, {required bool toPlan, required String source}) {
    _today = [..._today, ...added];
    final keys = {for (final e in added) ExerciseHistory.keyFor(e.name)};
    bool kept(Suggestion s) => !keys.contains(ExerciseHistory.keyFor(s.exercise.name));
    _suggestions = _suggestions?.where(kept).toList();
    _workout = _workout?.where(kept).toList();
    if (_recommendation != null) _recompute();
    _analytics?.extraAdded(count: added.length, toPlan: toPlan, source: source);
    _notify();
  }
}
