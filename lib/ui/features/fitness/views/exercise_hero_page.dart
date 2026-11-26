import 'dart:math' as math;

import 'package:fitness/data/repositories/body_tracking_repository.dart';
import 'package:fitness/data/services/api/youtube_video_cache.dart';
import 'package:fitness/data/services/coach/checkin_store.dart';
import 'package:fitness/data/services/coach/exercise_coach_service.dart';
import 'package:fitness/data/services/fitness/log_parser_service.dart';
import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/exercise_analytics.dart';
import 'package:fitness/data/services/workout_log/exercise_history_service.dart';
import 'package:fitness/data/services/workout_log/workout_log_remote_service.dart';
import 'package:fitness/domain/coach/exercise_catalog.dart';
import 'package:fitness/domain/coach/exercise_recommendation.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/session_volume.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/fitness/view_models/exercise_coach_view_model.dart';
import 'package:fitness/ui/features/fitness/views/exercise_detail/add_exercise_sheet.dart';
import 'package:fitness/ui/features/fitness/views/exercise_detail/coach_card.dart';
import 'package:fitness/ui/features/fitness/views/exercise_detail/detail_widgets.dart';
import 'package:fitness/ui/features/fitness/views/exercise_detail/session_card.dart';
import 'package:fitness/ui/features/fitness/views/exercise_detail/tutorials_tab.dart';
import 'package:fitness/ui/features/fitness/views/exercise_history_section.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_storage.dart';
import 'package:fitness/ui/features/video/views/exercise_videos_section.dart';
import 'package:fitness/data/services/video/video_tools.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/data/services/workout_log/workout_draft_storage.dart';
import 'package:fitness/domain/use_cases/exercise/search_youtube_videos_usecase.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/fitness/views/yt_player.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

export 'package:fitness/ui/features/fitness/views/exercise_detail/add_exercise_sheet.dart' show ExerciseAddOutcome;

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kLime     = Color(0xFFCCFF00);
const _kCard     = Color(0xFF111318);
const _kBorder   = Color(0xFF1E2330);
const _kDimWhite = Color(0x80FFFFFF);

class ExerciseHeroPage extends StatefulWidget {
  final Exercise exercise;
  final int exerciseIndex;
  final VoidCallback onComplete;

  /// Sets already logged for this exercise (restored from the workout draft).
  final List<DraftSet>? initialSets;

  /// Fired whenever the user edits a set, so the parent can persist it.
  final void Function(List<DraftSet>)? onSetsChanged;

  /// Which workout this is, saved with any video recorded here.
  final DateTime? workoutDate;
  final String? dayLabel;

  /// Every exercise in today's workout, which the coach counts sets over.
  final List<Exercise> sessionExercises;

  /// Adds exercises to today's workout, and to the saved plan when [toPlan].
  /// Without it the page suggests but cannot add.
  final Future<ExerciseAddOutcome> Function(List<Exercise> added, {required bool toPlan})? onAddExercises;

  /// Whether this workout is a day of the saved plan, so extras can go there.
  final Future<bool> Function()? canAddToPlan;

  /// Replaces the coach in tests and previews.
  final ExerciseCoachViewModel? coach;

  const ExerciseHeroPage({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onComplete,
    this.initialSets,
    this.onSetsChanged,
    this.workoutDate,
    this.dayLabel,
    this.sessionExercises = const [],
    this.onAddExercises,
    this.canAddToPlan,
    this.coach,
  });

  @override
  State<ExerciseHeroPage> createState() => _ExerciseHeroPageState();
}

class _ExerciseHeroPageState extends State<ExerciseHeroPage> {
  bool _isViewing = false;

  // Pro features on this page. Watched, so a purchase made from a locked card
  // opens them straight away.
  late final AccessPolicy _access = sl<AccessPolicy>();
  bool get _historyLocked => !_access.canUse(PremiumFeature.exerciseHistory);
  bool get _videosLocked => !_access.canUse(PremiumFeature.exerciseVideos);
  bool get _tutorialsLocked => !_access.canUse(PremiumFeature.videoTutorial);
  bool get _coachLocked => !_access.canUse(PremiumFeature.exerciseCoach);
  bool _historyWasLocked = false;
  bool _coachWasLocked = false;
  dynamic _videoContent;
  bool _isLoadingVideos = false;
  String? _errorMessage;
  final YouTubeVideoCache _videoCache = YouTubeVideoCache();

  // Controllers live here so data survives dialog close (X button).
  late final List<TextEditingController> _weightCtls;
  late final List<TextEditingController> _repsCtls;
  bool _logSaved = false;

  // What was logged for this exercise before. Started as the page opens so it
  // is usually ready by the time the user taps Log, and reused to pre-fill it.
  late Future<ExerciseHistory?> _history;
  bool _historyReported = false;

  // Records how this visit to the exercise is used (never the exercise name).
  late final ExerciseAnalytics _analytics =
      ExerciseAnalytics(widget.exercise, widget.exerciseIndex);

  late final ExerciseCoachViewModel _coach = widget.coach ??
      ExerciseCoachViewModel(
        exercise: widget.exercise,
        today: widget.sessionExercises,
        sessions: () => sl<ExerciseHistoryService>().sessions(),
        bodyGoal: () async => (await sl<BodyTrackingRepository>().load()).goal,
        profile: OnboardingStorage.loadOnboardingData,
        coach: sl<ExerciseCoach>(),
        checkIns: sl<CheckInStore>(),
        allowed: () => !_coachLocked,
        analytics: _analytics,
      );

  // 0 is My Videos, 1 is Tutorials. Videos exist only where filming does.
  int _tab = videoToolsSupported ? 0 : 1;
  final _sessionCard = GlobalKey();

  bool get _hasUnsavedData =>
      _weightCtls.any((c) => c.text.trim().isNotEmpty) && !_logSaved;

  @override
  void initState() {
    super.initState();
    final saved = widget.initialSets;
    _weightCtls = List.generate(
      widget.exercise.sets,
      (i) => TextEditingController(
          text: (saved != null && i < saved.length) ? saved[i].weight : ''),
    );
    _repsCtls = List.generate(
      widget.exercise.sets,
      (i) => TextEditingController(
          text: (saved != null && i < saved.length && saved[i].reps.isNotEmpty)
              ? saved[i].reps
              : widget.exercise.reps),
    );
    // Persist every keystroke through the parent so a kill mid-set loses nothing.
    for (final c in [..._weightCtls, ..._repsCtls]) {
      c.addListener(_publishSets);
    }
    _historyWasLocked = _historyLocked;
    _coachWasLocked = _coachLocked;
    _history = _loadHistory();
    _loadCachedVideos();
    _coach.load();
    _access.addListener(_onAccessChanged);
    _analytics.viewed();
    // This page is opened with a plain route, so the router does not see it.
    // Name the screen so events fired here are tagged with it.
    Analytics.screen('exercise');
  }

  /// Access changed (a purchase, a restore, a lapse). Read what just opened.
  void _onAccessChanged() {
    if (!mounted) return;
    if (_historyWasLocked && !_historyLocked) {
      _historyWasLocked = false;
      _reloadHistory();
    } else {
      _historyWasLocked = _historyLocked;
      setState(() {});
    }
    if (_coachWasLocked && !_coachLocked) _coach.load();
    _coachWasLocked = _coachLocked;
    if (!_tutorialsLocked) _loadCachedVideos();
  }

  Future<ExerciseHistory?> _loadHistory() async {
    // Not read at all for a free user: nothing is fetched or counted for
    // something they cannot see.
    if (_historyLocked) return null;
    final history = await sl<ExerciseHistoryService>().load(widget.exercise.name);
    // Once per visit: a refresh after saving should not count as a second look.
    if (!_historyReported) {
      _historyReported = true;
      _analytics.historyLoaded(history);
    }
    return history;
  }

  /// [fresh] drops the cached sessions first — used after a save, so the log
  /// just made appears, and by "Try again" after a failed read.
  void _reloadHistory({bool fresh = false}) {
    if (fresh) sl<ExerciseHistoryService>().invalidate();
    setState(() => _history = _loadHistory());
  }

  @override
  void dispose() {
    _access.removeListener(_onAccessChanged);
    // Leaving without Mark Complete (the back button, a swipe, a discard).
    _analytics.left(logged: _logSaved);
    // The workout list is the screen underneath.
    Analytics.screen('workout');
    for (final c in _weightCtls) { c.dispose(); }
    for (final c in _repsCtls) { c.dispose(); }
    if (widget.coach == null) _coach.dispose();
    super.dispose();
  }


  void _publishSets() {
    widget.onSetsChanged?.call([
      for (int i = 0; i < _weightCtls.length; i++)
        DraftSet(weight: _weightCtls[i].text, reps: _repsCtls[i].text),
    ]);
  }

  Future<void> _openLogDialog() async {
    // Wait briefly for the history so the dialog can show last time's numbers,
    // but never hold the dialog up for it: no history is a fine answer.
    List<LoggedSet> previous = const [];
    try {
      final history = await _history.timeout(
        const Duration(milliseconds: 800),
        onTimeout: () => null,
      );
      previous = history?.last?.sets ?? const [];
    } catch (_) {}
    if (!mounted) return;

    _analytics.logOpened(hadPrevious: previous.isNotEmpty);
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _WorkoutLogDialog(
        exerciseName: widget.exercise.name,
        sets: widget.exercise.sets,
        targetReps: widget.exercise.reps,
        weightCtls: _weightCtls,
        repsCtls: _repsCtls,
        previousSets: previous,
        analytics: _analytics,
      ),
    );
    if (saved == true && mounted) {
      await _saveToDatabase();
    } else {
      _analytics.logDismissed();
    }
  }

  Future<void> _saveToDatabase() async {
    try {
      final remote = sl<WorkoutLogRemoteDataSource>();
      // Build a plain Exercise with the actual reps/weight captured in the log
      // dialog, embedded in the sets notes field for record-keeping.
      final setsNotes = List.generate(widget.exercise.sets, (i) {
        final weight = _weightCtls[i].text.trim();
        final reps   = _repsCtls[i].text.trim();
        return 'set ${i + 1}: ${reps.isNotEmpty ? reps : '?'} reps'
               '${weight.isNotEmpty ? ' @ ${weight}kg' : ''}';
      }).join(' | ');

      final logged = Exercise(
        name:  widget.exercise.name,
        sets:  widget.exercise.sets,
        reps:  widget.exercise.reps,
        notes: setsNotes.isNotEmpty ? setsNotes : widget.exercise.notes,
      );

      await remote.saveCompleteSession(
        sessionDate: DateTime.now(),
        exercises: [logged],
        durationMins: 0,
      );
      _analytics.logSaved();
      if (mounted) {
        setState(() => _logSaved = true);
        _reloadHistory(fresh: true);
      }
    } catch (e) {
      _analytics.logSaveFailed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save log — $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _confirmLeave() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0F14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Save before leaving?',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('You have unsaved exercise data.',
            style: GoogleFonts.inter(color: const Color(0x80FFFFFF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: Text('Discard', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            child: Text('Save', style: GoogleFonts.inter(color: const Color(0xFFCCFF00))),
          ),
        ],
      ),
    );
    _analytics.leavePrompt(result ?? 'dismissed');
    if (result == 'save') {
      await _saveToDatabase();
      return true;
    }
    return result == 'discard';
  }

  void _loadCachedVideos() {
    // A list left in the cache from when the user had Pro must not show.
    if (_tutorialsLocked) return;
    final cached = _videoCache.getCachedVideos(widget.exercise.name);
    if (cached == null) return;
    final contents = cached['contents'];
    if (contents is List && contents.isNotEmpty) {
      setState(() {
        _videoContent = cached;
        _isViewing = true;
      });
    }
  }

  Future<void> _loadVideos() async {
    if (_tutorialsLocked) return;
    if (_videoCache.hasCachedVideos(widget.exercise.name)) {
      _analytics.tutorialsLoaded(success: true, cached: true);
      setState(() {
        _videoContent = _videoCache.getCachedVideos(widget.exercise.name);
        _isViewing = true;
        _isLoadingVideos = false;
      });
      return;
    }

    setState(() {
      _isLoadingVideos = true;
      _errorMessage = null;
    });

    try {
      final result = await sl<SearchYouTubeVideosUsecase>()(
        widget.exercise.name,
        maxResults: 10,
      );
      _videoCache.cacheVideos(widget.exercise.name, result);
      final contents = result is Map ? result['contents'] : null;
      _analytics.tutorialsLoaded(
          success: true, count: contents is List ? contents.length : null);
      if (!mounted) return;
      setState(() {
        _videoContent = result;
        _isViewing = true;
        _isLoadingVideos = false;
      });
    } catch (e) {
      _analytics.tutorialsLoaded(success: false);
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoadingVideos = false;
      });
    }
  }

  // ── The coach ─────────────────────────────────────────────────────────────

  /// Puts the recommended numbers into the log and opens it to be checked.
  void _use(SetPrescription p, {required bool alternative}) {
    final weight = p.weightKg;
    for (var i = 0; i < _weightCtls.length; i++) {
      if (weight != null) _weightCtls[i].text = formatKg(weight);
      _repsCtls[i].text = p.reps;
    }
    _coach.used(alternative: alternative);
    _openLogDialog();
  }

  Future<void> _addExercises(List<Suggestion> picks, String source) async {
    final add = widget.onAddExercises;
    if (add == null || picks.isEmpty) return;
    final toPlan = await showAddExerciseChoice(
      context,
      names: [for (final p in picks) p.exercise.name],
      canAddToPlan: widget.canAddToPlan?.call(),
    );
    if (toPlan == null || !mounted) return;
    final exercises = [for (final p in picks) p.toExercise()];
    final outcome = await add(exercises, toPlan: toPlan);
    if (!mounted) return;
    _coach.addedToSession(exercises,
        toPlan: outcome == ExerciseAddOutcome.todayAndPlan, source: source);
    final what = exercises.length == 1 ? exercises.single.name : '${exercises.length} exercises';
    _snack(switch (outcome) {
      ExerciseAddOutcome.today => 'Added $what to today\'s workout.',
      ExerciseAddOutcome.todayAndPlan => 'Added $what to today and to your plan.',
      ExerciseAddOutcome.planFailed => 'Added $what to today, but your plan could not be saved.',
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── The menu ──────────────────────────────────────────────────────────────

  Future<void> _openMenu() async {
    final notes = widget.exercise.notes;
    final choice = await showBodySheet<String>(
      context,
      (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            if (notes != null)
              _MenuRow(Icons.notes_rounded, 'Technique notes', () => Navigator.of(sheet).pop('notes')),
            _MenuRow(Icons.history_rounded, 'Full history', () => Navigator.of(sheet).pop('history')),
            if (widget.onAddExercises != null)
              _MenuRow(Icons.add_rounded, 'Add an exercise', () => Navigator.of(sheet).pop('add')),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'notes':
        await _showNotes(notes!);
      case 'history':
        await requirePremium(context, PremiumFeature.exerciseHistory, _showFullHistory);
      case 'add':
        await requirePremium(context, PremiumFeature.exerciseCoach, _suggestFromMenu);
    }
  }

  Future<void> _showNotes(String notes) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0D0F14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Technique notes', style: bodyHeading(17)),
          content: Text(notes, style: bodyText(14, color: kBodySoft, height: 1.6)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Close', style: bodyText(13, color: kBodyLime, weight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Future<void> _showFullHistory() async {
    final history = await _history;
    if (!mounted) return;
    if (history == null || history.isEmpty) {
      _snack(history == null ? 'Your history could not be loaded.' : 'No history for this exercise yet.');
      return;
    }
    showExerciseHistory(context, history, widget.exercise.name, DateTime.now());
  }

  Future<void> _suggestFromMenu() async {
    if (_coach.recommendation == null) await _coach.load();
    await _coach.suggest();
    final target = _sessionCard.currentContext;
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300), alignment: 0.1);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Widget _stats() => FutureBuilder<ExerciseHistory?>(
        future: _history,
        builder: (context, snap) {
          final top = snap.data?.last?.bestSet?.weightKg;
          final target = widget.exercise.targetKg;
          return DetailStats(
            sets: widget.exercise.sets,
            reps: widget.exercise.reps,
            lastWeight: top == null || top == 0 ? null : '${formatKg(top)} kg',
            lastWeightLocked: _historyLocked,
            target: target == null ? null : '${formatKg(target)} kg',
            onTapLog: _openLogDialog,
          );
        },
      );

  Widget _media() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Recording and rating your own sets: iOS only for now.
            if (videoToolsSupported) ...[
              _Tab('My Videos', selected: _tab == 0, locked: _videosLocked, onTap: () => setState(() => _tab = 0)),
              const SizedBox(width: 24),
            ],
            _Tab('Tutorials', selected: _tab == 1, locked: _tutorialsLocked, onTap: () => setState(() => _tab = 1)),
          ],
        ),
        const SizedBox(height: 14),
        if (_tab == 0 && videoToolsSupported)
          _videosLocked
              ? const PremiumLockedCard(feature: PremiumFeature.exerciseVideos)
              : ExerciseVideosSection(
                  tabbed: true,
                  exerciseName: widget.exercise.name,
                  muscles: MuscleCoverage.musclesFor(
                    name: widget.exercise.name,
                    notes: widget.exercise.notes ?? '',
                  ),
                  workoutDate: widget.workoutDate,
                  dayLabel: widget.dayLabel,
                )
        else
          TutorialsTab(
            locked: _tutorialsLocked,
            isViewing: _isViewing,
            isLoading: _isLoadingVideos,
            errorMessage: _errorMessage,
            videoContent: _videoContent,
            onLoad: _loadVideos,
            onVideoTap: (videoId) => requirePremium(
              context,
              PremiumFeature.videoTutorial,
              () async {
                _analytics.tutorialOpened();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => YouTubePlayer(videoId: videoId),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_hasUnsavedData) {
          final leave = await _confirmLeave();
          if (leave && context.mounted) Navigator.of(context).pop();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: kBodyBg,
        body: SafeArea(
          child: Column(
            children: [
              DetailHeader(onMenu: _openMenu),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExerciseHeading(exercise: widget.exercise),
                      const SizedBox(height: 16),
                      _stats(),
                      const SizedBox(height: 14),
                      SafetyTipCard(notes: widget.exercise.notes),
                      const SizedBox(height: 14),
                      if (_coachLocked)
                        PremiumLockedCard(feature: PremiumFeature.exerciseCoach, onUnlocked: _coach.load)
                      else
                        ListenableBuilder(
                          listenable: _coach,
                          builder: (_, __) => CoachCard(vm: _coach, onUse: _use),
                        ),
                      const SizedBox(height: 22),
                      _media(),
                      const SizedBox(height: 22),
                      ExerciseHistorySection(
                        compact: true,
                        exerciseName: widget.exercise.name,
                        history: _history,
                        onRetry: () => _reloadHistory(fresh: true),
                        locked: _historyLocked,
                      ),
                      if (!_coachLocked) ...[
                        const SizedBox(height: 14),
                        ListenableBuilder(
                          key: _sessionCard,
                          listenable: _coach,
                          builder: (_, __) => SessionCard(
                            vm: _coach,
                            onAdd: widget.onAddExercises == null ? null : _addExercises,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              CompleteExerciseButton(onComplete: () {
                _analytics.completed(logged: _logSaved);
                widget.onComplete();
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tab of the videos area, underlined when chosen.
class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  const _Tab(this.label, {required this.selected, required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: bodyHeading(15, color: selected ? Colors.white : kBodyMuted)
                            .copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
                    if (locked) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.lock_outline_rounded, size: 13, color: kBodyMuted),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: selected ? kBodyLime : Colors.transparent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuRow(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: kBodyLime, size: 20),
        title: Text(label, style: bodyText(14, weight: FontWeight.w600)),
        onTap: onTap,
      );
}

// ── Workout log dialog ────────────────────────────────────────────────────────

class _WorkoutLogDialog extends StatefulWidget {
  final String exerciseName;
  final int sets;
  final String targetReps;
  final List<TextEditingController> weightCtls;
  final List<TextEditingController> repsCtls;

  /// The sets from the last time this exercise was logged, if any.
  final List<LoggedSet> previousSets;

  /// Records what is done inside the dialog.
  final ExerciseAnalytics? analytics;

  const _WorkoutLogDialog({
    required this.exerciseName,
    required this.sets,
    required this.targetReps,
    required this.weightCtls,
    required this.repsCtls,
    this.previousSets = const [],
    this.analytics,
  });

  @override
  State<_WorkoutLogDialog> createState() => _WorkoutLogDialogState();
}

class _WorkoutLogDialogState extends State<_WorkoutLogDialog> {
  List<TextEditingController> get _weightCtls => widget.weightCtls;
  List<TextEditingController> get _repsCtls => widget.repsCtls;

  /// Last time's set for row [i]. A longer workout reuses the final set rather
  /// than leaving the extra rows without a hint.
  LoggedSet? _previousFor(int i) {
    final prev = widget.previousSets;
    if (prev.isEmpty) return null;
    return prev[i < prev.length ? i : prev.length - 1];
  }

  /// Copy last time's weights and reps into the fields. It only fills what the
  /// last session recorded, so a bodyweight set leaves the weight box alone.
  void _fillFromLast() {
    widget.analytics?.sameAsLast();
    for (var i = 0; i < widget.sets; i++) {
      final p = _previousFor(i);
      if (p == null) continue;
      if (p.weightText != null) _weightCtls[i].text = p.weightText!;
      if (p.repsText != null) _repsCtls[i].text = p.repsText!;
    }
    setState(() {});
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  // Made only when voice logging is used.
  late final _logParser = LogParserService();
  bool _sttAvailable = false;
  bool _isListening = false;
  bool _isParsing = false;
  bool _userStopped = false;
  double _soundLevel = 0.0;
  String _statusText = '';
  String _liveText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _sttAvailable = await _speech.initialize(
      onStatus: (status) {
        // The engine reports 'done'/'notListening' after each utterance segment.
        // If the user hasn't tapped stop, restart immediately to keep listening.
        if ((status == 'done' || status == 'notListening') && mounted) {
          if (_isListening && !_userStopped) {
            _restartListening();
          }
        }
      },
      onError: (e) {
        // Restart on transient errors (e.g. network, no-speech timeout)
        // unless the user explicitly stopped.
        if (mounted && _isListening && !_userStopped) {
          _restartListening();
        } else if (mounted) {
          setState(() { _isListening = false; _statusText = 'Error: ${e.errorMsg}'; });
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _restartListening() async {
    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted || _userStopped) return;
    await _startSession();
  }

  Future<void> _startSession() async {
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        // Accumulate words — keep building liveText with every partial result.
        setState(() => _liveText = result.recognizedWords);
      },
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _soundLevel = level.clamp(0, 10) / 10);
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 30), // long enough not to interrupt naturally
        localeId: 'en_US',
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (!_sttAvailable) {
      setState(() => _statusText = 'Speech recognition not available');
      return;
    }
    if (_isListening) {
      _userStopped = true;
      await _speech.stop();
      final captured = _liveText;
      setState(() { _isListening = false; _soundLevel = 0; });
      if (captured.trim().isNotEmpty) {
        await _parseWithAI(captured);
      }
      return;
    }
    _userStopped = false;
    widget.analytics?.voice('started');
    setState(() { _isListening = true; _liveText = ''; _soundLevel = 0; _statusText = ''; });
    await _startSession();
  }

  Future<void> _parseWithAI(String transcript) async {
    if (!mounted) return;
    setState(() { _isParsing = true; _statusText = ''; });
    try {
      final sets = await _logParser.parseSpeech(
        transcript: transcript,
        numSets: widget.sets,
      );
      if (!mounted) return;
      for (var i = 0; i < sets.length && i < widget.sets; i++) {
        final s = sets[i];
        if (s.weightKg != null) {
          _weightCtls[i].text = s.weightKg! % 1 == 0
              ? s.weightKg!.toInt().toString()
              : s.weightKg!.toStringAsFixed(1);
        }
        if (s.reps != null) {
          _repsCtls[i].text = s.reps!.toString();
        }
      }
      widget.analytics?.voice('parsed', sets: sets.length);
      setState(() { _isParsing = false; _liveText = ''; });
    } catch (_) {
      widget.analytics?.voice('failed');
      if (!mounted) return;
      // AI failed — keep the transcript visible so the user can enter manually
      setState(() { _isParsing = false; _statusText = 'Could not parse — please fill in manually'; });
    }
  }

  void _onSaveLog() {
    // Collect which set numbers have incomplete data.
    final emptySets = <int>[];
    for (var i = 0; i < widget.sets; i++) {
      final weightMissing = _weightCtls[i].text.trim().isEmpty;
      final repsMissing = _repsCtls[i].text.trim().isEmpty;
      if (weightMissing || repsMissing) emptySets.add(i + 1);
    }

    if (emptySets.isNotEmpty) {
      widget.analytics?.logIncomplete(emptySets.length);
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0D0F14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Incomplete sets',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: Text(
            'Please fill in weight and reps for set${emptySets.length > 1 ? 's' : ''} '
            '${emptySets.join(', ')} before saving.',
            style: GoogleFonts.inter(
              color: const Color(0x80FFFFFF),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Got it',
                style: GoogleFonts.inter(color: const Color(0xFFCCFF00)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // All sets complete — pop with true so the parent saves to DB.
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _userStopped = true;
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kLime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _kLime.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.edit_note_rounded, color: _kLime, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exerciseName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.sets} sets · ${widget.targetReps} reps target',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _kDimWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Voice-log mic ────────────────────────────────────────
                  GestureDetector(
                    onTap: _sttAvailable ? _toggleListening : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? _kLime
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isListening
                              ? _kLime
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: _isListening
                            ? Colors.black
                            : (_sttAvailable ? _kLime : Colors.white24),
                        size: 18,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Column labels ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const SizedBox(width: 44),
                  Expanded(
                    child: Text(
                      'Weight (kg)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kDimWhite,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reps done',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kDimWhite,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            ),
            const SizedBox(height: 8),
            // ── Set rows / waveform / parsing indicator ──────────────────────
            if (_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _WaveformView(level: _soundLevel, liveText: _liveText),
              )
            else if (_isParsing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 28, height: 28,
                      child: CircularProgressIndicator(
                        color: _kLime, strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AI is parsing your log…',
                      style: GoogleFonts.inter(fontSize: 13, color: _kDimWhite),
                    ),
                    if (_liveText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"$_liveText"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white38,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      if (widget.previousSets.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _fillFromLast,
                            icon: const Icon(Icons.history_rounded,
                                size: 16, color: _kLime),
                            label: Text(
                              'Same as last time',
                              style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _kLime),
                            ),
                          ),
                        ),
                      ...List.generate(
                        widget.sets,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SetRow(
                            setNumber: i + 1,
                            weightCtl: _weightCtls[i],
                            repsCtl: _repsCtls[i],
                            previous: _previousFor(i),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_statusText.isNotEmpty && !_isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _statusText,
                  style: GoogleFonts.inter(fontSize: 12, color: _kDimWhite),
                ),
              ),
            // ── Save button ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSaveLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kLime,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save log',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Waveform animation ────────────────────────────────────────────────────────

class _WaveformView extends StatefulWidget {
  final double level;
  final String liveText;

  const _WaveformView({required this.level, required this.liveText});

  @override
  State<_WaveformView> createState() => _WaveformViewState();
}

class _WaveformViewState extends State<_WaveformView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(7, (i) {
                final phase = (i / 7) * 2 * math.pi;
                final base = (math.sin(_ctrl.value * 2 * math.pi + phase) + 1) / 2;
                final height = 12.0 + (base * 44 * (0.3 + widget.level * 0.7));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 5,
                    height: height,
                    decoration: BoxDecoration(
                      color: _kLime.withValues(alpha: 0.7 + base * 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.liveText.isNotEmpty
              ? Container(
                  key: const ValueKey('live'),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kLime.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kLime.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    widget.liveText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                )
              : Text(
                  key: const ValueKey('hint'),
                  'Say: "80 kilos 10 reps, 75 kilos 8 reps"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white30),
                ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Set rows ──────────────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  final int setNumber;
  final TextEditingController weightCtl;
  final TextEditingController repsCtl;

  /// What this set was last time; shown as the empty-field hint.
  final LoggedSet? previous;

  const _SetRow({
    required this.setNumber,
    required this.weightCtl,
    required this.repsCtl,
    this.previous,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Set number bubble
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _kLime.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$setNumber',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kLime,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Weight field
          Expanded(
              child: _LogField(
                  controller: weightCtl,
                  hint: previous?.weightText ?? '0',
                  suffix: 'kg')),
          const SizedBox(width: 12),
          // Reps field
          Expanded(
              child: _LogField(
                  controller: repsCtl,
                  hint: previous?.repsText ?? '0',
                  suffix: 'reps')),
        ],
      ),
    );
  }
}

class _LogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;

  const _LogField({
    required this.controller,
    required this.hint,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.25),
        ),
        suffixText: suffix,
        suffixStyle: GoogleFonts.inter(
          fontSize: 11,
          color: _kDimWhite,
        ),
        filled: true,
        fillColor: _kCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _kBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kLime, width: 1.5),
        ),
      ),
    );
  }
}
