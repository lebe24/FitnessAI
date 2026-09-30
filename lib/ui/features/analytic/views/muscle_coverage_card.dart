import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/muscle_map/views/body_figure.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kCard = Color(0xFF111318);
const _kCard2 = Color(0xFF161B26);
const _kBorder = Color(0xFF1E2330);
const _kSub = Color(0x80FFFFFF);
const _kLime = Color(0xFFCCFF00);

/// Which muscles the logged sessions actually trained, drawn on the body.
///
/// The volume chart above answers "am I doing more than I was". This answers
/// "more of what" — and the two share a source, so the map cannot disagree
/// with the chart about what was logged.
///
/// Shading is relative to the hardest-worked muscle in the same sessions, so
/// it reads as a distribution rather than an absolute score. Muscles the
/// training never reached stay dark, which is the point: the gaps are the
/// information.
class MuscleCoverageCard extends StatefulWidget {
  final List<WorkoutSessionModel> sessions;
  final bool isLoading;

  const MuscleCoverageCard({
    super.key,
    required this.sessions,
    required this.isLoading,
  });

  @override
  State<MuscleCoverageCard> createState() => _MuscleCoverageCardState();
}

class _MuscleCoverageCardState extends State<MuscleCoverageCard> {
  BodyMap? _map;

  @override
  void initState() {
    super.initState();
    BodyMapSource.load().then((map) {
      if (mounted) setState(() => _map = map);
    }).catchError((_) {
      // The readout below still works without the drawing.
    });
  }

  /// A lime ramp: barely lit for a muscle that got one set, full for the one
  /// that got the most.
  Color? _fillFor(String slug, Map<String, int> levels) {
    return switch (levels[slug] ?? 0) {
      >= 4 => _kLime,
      3 => _kLime.withValues(alpha: 0.66),
      2 => _kLime.withValues(alpha: 0.42),
      1 => _kLime.withValues(alpha: 0.22),
      _ => _kCard2,
    };
  }

  @override
  Widget build(BuildContext context) {
    final locked = !sl<AccessPolicy>().canUse(PremiumFeature.trainingVolume);
    final coverage = locked
        ? MuscleCoverage.empty
        : MuscleCoverage.fromSessions(widget.sessions);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(locked: locked, sessions: widget.sessions.length),
          const SizedBox(height: 18),
          if (locked)
            const _Locked()
          else if (widget.isLoading)
            const _Loading()
          else if (coverage.isEmpty)
            const _Empty()
          else ...[
            _Figures(
              map: _map,
              levels: coverage.levels,
              fillFor: _fillFor,
            ),
            const SizedBox(height: 14),
            const _Legend(),
            const SizedBox(height: 14),
            _TopMuscles(coverage: coverage),
            if (coverage.unresolvedExercises > 0) ...[
              const SizedBox(height: 12),
              _Unresolved(count: coverage.unresolvedExercises),
            ],
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool locked;
  final int sessions;
  const _Header({required this.locked, required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kLime.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.accessibility_new_rounded,
              size: 19, color: _kLime),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Muscles trained',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(
                locked
                    ? 'See where your training lands'
                    : sessions == 0
                        ? 'Log a session to see where it lands'
                        : 'Across your last $sessions sessions',
                style: GoogleFonts.inter(fontSize: 11.5, color: _kSub),
              ),
            ],
          ),
        ),
        if (locked) const PremiumBadge(visible: true),
      ],
    );
  }
}

class _Figures extends StatelessWidget {
  final BodyMap? map;
  final Map<String, int> levels;
  final Color? Function(String slug, Map<String, int> levels) fillFor;

  const _Figures({
    required this.map,
    required this.levels,
    required this.fillFor,
  });

  @override
  Widget build(BuildContext context) {
    final map = this.map;
    if (map == null) {
      return const SizedBox(height: 220, child: _Loading());
    }
    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: BodyFigure(
              view: map.front,
              fillFor: (slug) => fillFor(slug, levels),
              silhouetteColor: const Color(0xFF14171F),
              outlineColor: _kCard,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: BodyFigure(
              view: map.back,
              fillFor: (slug) => fillFor(slug, levels),
              silhouetteColor: const Color(0xFF14171F),
              outlineColor: _kCard,
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
        Text('Less',
            style: GoogleFonts.inter(fontSize: 10.5, color: _kSub)),
        const SizedBox(width: 8),
        for (final a in [0.22, 0.42, 0.66, 1.0]) ...[
          Container(
            width: 18,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: a),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Text('More',
            style: GoogleFonts.inter(fontSize: 10.5, color: _kSub)),
      ],
    );
  }
}

/// The five hardest-worked muscles, with the sets behind the shading.
///
/// The drawing says where; a reader who wants the number should not have to
/// judge it from a colour.
class _TopMuscles extends StatelessWidget {
  final MuscleCoverage coverage;
  const _TopMuscles({required this.coverage});

  @override
  Widget build(BuildContext context) {
    final top = coverage.ranked.take(5).toList();
    final max = coverage.load[top.first] ?? 1;

    return Column(
      children: [
        for (final slug in top)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    Muscle.bySlug(slug)?.name ?? slug,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (coverage.load[slug] ?? 0) / max,
                      minHeight: 6,
                      backgroundColor: _kCard2,
                      valueColor: const AlwaysStoppedAnimation<Color>(_kLime),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(coverage.load[slug] ?? 0).round()} sets',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(fontSize: 11, color: _kSub),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Says out loud how much training the map could not place.
///
/// The muscles are read from the coaching text a plan writes next to each
/// exercise, and not every exercise has it. Quietly dropping those would make
/// the map look more complete than it is.
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
            '$count logged ${count == 1 ? 'exercise' : 'exercises'} '
            '${count == 1 ? 'does' : 'do'} not say which muscles '
            '${count == 1 ? 'it works' : 'they work'}, so '
            '${count == 1 ? 'it is' : 'they are'} not on the map.',
            style: GoogleFonts.inter(
                fontSize: 10.5, height: 1.45, color: _kSub),
          ),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 220,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kLime),
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.accessibility_new_rounded,
                size: 34, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 10),
            Text('Nothing logged yet',
                style: GoogleFonts.inter(fontSize: 13, color: _kSub)),
            const SizedBox(height: 4),
            Text('Finish a session and your muscles light up here',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11.5, color: _kSub)),
          ],
        ),
      ),
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _kLime.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.lock_rounded, color: _kLime, size: 20),
            ),
            const SizedBox(height: 12),
            Text('See which muscles you actually train',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85))),
            const SizedBox(height: 4),
            Text('And the ones your plan keeps missing',
                style: GoogleFonts.inter(fontSize: 11.5, color: _kSub)),
          ],
        ),
      ),
    );
  }
}
