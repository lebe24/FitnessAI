import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/data/services/workout_log/session_supabase_source.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/muscle_map/views/body_figure.dart';
import 'package:fitness/ui/features/muscle_map/views/muscle_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBg = Color(0xFF0A0C12);
const _kCard = Color(0xFF111318);
const _kCard2 = Color(0xFF161B26);
const _kBorder = Color(0xFF1E2330);
const _kLime = Color(0xFFCCFF00);
const _kDim = Color(0x80FFFFFF);

/// The body, shaded by what the user has actually trained.
///
/// The shading is the point: a muscle the training keeps missing stays dark,
/// and the gaps are what someone opens this screen to find. Tapping any muscle
/// — on the body or in the list — opens what it took to build it.
class MuscleMapPage extends StatefulWidget {
  const MuscleMapPage({super.key});

  @override
  State<MuscleMapPage> createState() => _MuscleMapPageState();
}

class _MuscleMapPageState extends State<MuscleMapPage> {
  BodyMap? _map;
  bool _mapFailed = false;

  List<WorkoutSessionModel> _sessions = const [];
  bool _sessionsLoading = true;
  MuscleCoverage _coverage = MuscleCoverage.empty;

  @override
  void initState() {
    super.initState();
    _loadMap();
    _loadSessions();
  }

  Future<void> _loadMap() async {
    setState(() => _mapFailed = false);
    try {
      final map = await BodyMapSource.load();
      if (mounted) setState(() => _map = map);
    } catch (_) {
      if (mounted) setState(() => _mapFailed = true);
    }
  }

  Future<void> _loadSessions() async {
    // The same source and limit the analytics page uses, so the two screens
    // cannot disagree about how much was trained.
    final sessions = await sl<SessionSupabaseSource>().listSessions(limit: 100);
    if (!mounted) return;
    setState(() {
      _sessions = sessions ?? const [];
      _coverage = MuscleCoverage.fromSessions(_sessions);
      _sessionsLoading = false;
    });
  }

  Color? _fillFor(String slug) {
    return switch (_coverage.levels[slug] ?? 0) {
      >= 4 => _kLime,
      3 => _kLime.withValues(alpha: 0.66),
      2 => _kLime.withValues(alpha: 0.42),
      1 => _kLime.withValues(alpha: 0.22),
      _ => _kCard2,
    };
  }

  void _open(String slug) {
    final muscle = Muscle.bySlug(slug);
    if (muscle == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MuscleDetailPage(
          muscle: muscle,
          coverage: _coverage,
          sessionCount: _sessions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Title(sessions: _sessions.length, loading: _sessionsLoading),
                    const SizedBox(height: 20),
                    _FiguresCard(
                      map: _map,
                      failed: _mapFailed,
                      loading: _sessionsLoading,
                      fillFor: _fillFor,
                      onSelect: _open,
                      onRetry: _loadMap,
                    ),
                    const SizedBox(height: 14),
                    const _Legend(),
                    const SizedBox(height: 22),
                    _MuscleList(coverage: _coverage, onSelect: _open),
                    if (_coverage.unresolvedExercises > 0) ...[
                      const SizedBox(height: 14),
                      _Unresolved(count: _coverage.unresolvedExercises),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chrome ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onBack,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final int sessions;
  final bool loading;
  const _Title({required this.sessions, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
            children: const [
              TextSpan(text: 'Muscle '),
              TextSpan(
                text: 'Map',
                style: TextStyle(backgroundColor: _kLime, color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loading
              ? 'Reading your training…'
              : sessions == 0
                  ? 'Log a session and the body lights up with what you trained.'
                  : 'Shaded by your last $sessions sessions. Tap a muscle to see '
                      'what built it.',
          style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: _kDim),
        ),
      ],
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _FiguresCard extends StatelessWidget {
  final BodyMap? map;
  final bool failed;
  final bool loading;
  final Color? Function(String slug) fillFor;
  final ValueChanged<String> onSelect;
  final VoidCallback onRetry;

  const _FiguresCard({
    required this.map,
    required this.failed,
    required this.loading,
    required this.fillFor,
    required this.onSelect,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final map = this.map;
    final Widget body;
    if (failed) {
      body = _MapError(onRetry: onRetry);
    } else if (map == null || loading) {
      body = const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_kLime),
          strokeWidth: 2.5,
        ),
      );
    } else {
      body = Row(
        children: [
          Expanded(
            child: _LabelledFigure(
              label: 'Front',
              view: map.front,
              fillFor: fillFor,
              onSelect: onSelect,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _LabelledFigure(
              label: 'Back',
              view: map.back,
              fillFor: fillFor,
              onSelect: onSelect,
            ),
          ),
        ],
      );
    }

    return Container(
      height: 380,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: body,
    );
  }
}

class _LabelledFigure extends StatelessWidget {
  final String label;
  final BodyView view;
  final Color? Function(String slug) fillFor;
  final ValueChanged<String> onSelect;

  const _LabelledFigure({
    required this.label,
    required this.view,
    required this.fillFor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Semantics(
            label: '$label of body. Tap a muscle to see how you trained it.',
            child: BodyFigure(
              view: view,
              fillFor: fillFor,
              onSelect: onSelect,
              silhouetteColor: const Color(0xFF14171F),
              outlineColor: _kCard,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: _kDim,
          ),
        ),
      ],
    );
  }
}

class _MapError extends StatelessWidget {
  final VoidCallback onRetry;
  const _MapError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "The body map couldn't load",
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'You can still pick a muscle from the list below.',
            style: GoogleFonts.inter(fontSize: 12, color: _kDim),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Text('Retry',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kLime)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Less', style: GoogleFonts.inter(fontSize: 10.5, color: _kDim)),
        const SizedBox(width: 8),
        for (final a in [0.22, 0.42, 0.66, 1.0])
          Container(
            width: 20,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: a),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 8),
        Text('More', style: GoogleFonts.inter(fontSize: 10.5, color: _kDim)),
      ],
    );
  }
}

// ── Muscle list ───────────────────────────────────────────────────────────────

/// Every muscle, trained ones first with their share.
///
/// The list exists because small regions like the shins are hard to hit with a
/// finger, and because it works when the drawing fails to load or a screen
/// reader is driving.
class _MuscleList extends StatelessWidget {
  final MuscleCoverage coverage;
  final ValueChanged<String> onSelect;

  const _MuscleList({required this.coverage, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final trained = coverage.ranked;
    final untrained = Muscle.all
        .map((m) => m.slug)
        .where((s) => !trained.contains(s))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slug in [...trained, ...untrained])
          _MuscleRow(
            muscle: Muscle.bySlug(slug)!,
            share: coverage.sharePercent(slug),
            level: coverage.levels[slug] ?? 0,
            onTap: () => onSelect(slug),
          ),
      ],
    );
  }
}

class _MuscleRow extends StatelessWidget {
  final Muscle muscle;
  final double share;
  final int level;
  final VoidCallback onTap;

  const _MuscleRow({
    required this.muscle,
    required this.share,
    required this.level,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final untrained = level == 0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: untrained
                    ? _kCard2
                    : _kLime.withValues(alpha: [0.22, 0.42, 0.66, 1.0][level - 1]),
                shape: BoxShape.circle,
                border: untrained
                    ? Border.all(color: Colors.white.withValues(alpha: 0.12))
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                muscle.name,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: untrained ? 0.45 : 0.9),
                ),
              ),
            ),
            Text(
              untrained ? 'Not trained' : '${share.round()}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: untrained ? FontWeight.w400 : FontWeight.w600,
                color: untrained ? _kDim : _kLime,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _Unresolved extends StatelessWidget {
  final int count;
  const _Unresolved({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded,
            size: 13, color: Colors.white.withValues(alpha: 0.35)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$count logged ${count == 1 ? 'exercise does' : 'exercises do'} not '
            'say which muscles ${count == 1 ? 'it works' : 'they work'}, so '
            '${count == 1 ? 'it is' : 'they are'} not shaded here.',
            style: GoogleFonts.inter(fontSize: 10.5, height: 1.45, color: _kDim),
          ),
        ),
      ],
    );
  }
}
