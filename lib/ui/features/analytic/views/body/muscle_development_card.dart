import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/muscle_focus.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/muscle_map/views/body_figure.dart';
import 'package:flutter/material.dart';

/// The body, shaded by how each muscle group is developing: lime for strong,
/// blue for average, amber for focus areas, grey for untrained.
class MuscleDevelopmentCard extends StatefulWidget {
  final List<MuscleStatus> muscles;
  final ValueChanged<MuscleStatus> onSelect;
  final bool loading;

  const MuscleDevelopmentCard({
    super.key,
    required this.muscles,
    required this.onSelect,
    this.loading = false,
  });

  @override
  State<MuscleDevelopmentCard> createState() => _MuscleDevelopmentCardState();
}

class _MuscleDevelopmentCardState extends State<MuscleDevelopmentCard> {
  BodyMap? _map;

  @override
  void initState() {
    super.initState();
    BodyMapSource.load().then((m) {
      if (mounted) setState(() => _map = m);
    }).catchError((_) {
      // The chips below still work without the drawing.
    });
  }

  MuscleStatus? _statusForSlug(String slug) {
    final g = MuscleGroup.forSlug(slug);
    if (g == null) return null;
    for (final m in widget.muscles) {
      if (m.group == g) return m;
    }
    return null;
  }

  Color? _fill(String slug) {
    final s = _statusForSlug(slug);
    return s == null ? null : levelColor(s.level);
  }

  void _tap(String slug) {
    final s = _statusForSlug(slug);
    if (s != null) widget.onSelect(s);
  }

  @override
  Widget build(BuildContext context) {
    final trained = [for (final m in widget.muscles) if (m.level != MuscleLevel.untrained) m]
      ..sort((a, b) => b.score.compareTo(a.score));

    return BodyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'Muscle Development Map',
            subtitle: 'From your last four weeks of training. Tap a muscle to see why and to focus on it.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 270,
            child: _map == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kBodyLime))
                : Row(
                    children: [
                      Expanded(child: _figure(_map!.front)),
                      const SizedBox(width: 8),
                      Expanded(child: _figure(_map!.back)),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          const _Legend(),
          if (trained.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final m in trained) _GroupChip(status: m, onTap: () => widget.onSelect(m))],
            ),
          ] else if (!widget.loading) ...[
            const SizedBox(height: 14),
            Text(
              'Log a few workouts with sets and weights and your muscles light up here.',
              style: bodyText(12.5, color: kBodyMuted, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  Widget _figure(BodyView view) => BodyFigure(
        view: view,
        onSelect: _tap,
        fillFor: _fill,
        muscleColor: kBodyUntrained,
        silhouetteColor: const Color(0xFF1B2030),
        outlineColor: kBodyCard,
      );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget dot(MuscleLevel l) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: levelColor(l),
                shape: BoxShape.circle,
                border: l == MuscleLevel.untrained ? Border.all(color: kBodyMuted.withValues(alpha: 0.4)) : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(levelLabel(l), style: bodyText(11, color: kBodyMuted)),
          ],
        );
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [for (final l in MuscleLevel.values) dot(l)],
    );
  }
}

class _GroupChip extends StatelessWidget {
  final MuscleStatus status;
  final VoidCallback onTap;
  const _GroupChip({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = levelColor(status.level);
    return Semantics(
      button: true,
      label: '${status.group.label}, ${levelLabel(status.level)}, ${status.score} out of 10',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status.pinned) ...[Icon(Icons.push_pin_rounded, size: 12, color: c), const SizedBox(width: 4)],
              Text(status.group.label, style: bodyText(12, weight: FontWeight.w600)),
              const SizedBox(width: 7),
              Text('${status.score}', style: bodyText(12, color: c, weight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Strengths and focus areas ────────────────────────────────────────────────

/// What to do about a muscle, in one sentence, from its numbers.
String muscleSuggestion(MuscleStatus s) {
  final gap = s.targetSets - s.weeklySets;
  if (s.weeklySets == 0) return 'Add about ${s.targetSets.ceil()} sets a week to get it going.';
  if (gap > 0.5) {
    return 'Add ${gap.ceil()} ${gap.ceil() == 1 ? 'set' : 'sets'} a week to reach about ${_n(s.targetSets)}.';
  }
  if (s.pinned) return 'Pinned as a focus. Add weight whenever the sets feel easy.';
  return 'Good volume. Keep adding weight as you can.';
}

String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

class StrengthsFocusCard extends StatelessWidget {
  final List<MuscleStatus> strengths;
  final List<MuscleStatus> focusAreas;
  final ValueChanged<MuscleStatus> onSelect;

  const StrengthsFocusCard({
    super.key,
    required this.strengths,
    required this.focusAreas,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (strengths.isEmpty && focusAreas.isEmpty) return const SizedBox.shrink();
    return BodyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Strengths & Focus Areas', style: bodyHeading(16)),
          if (focusAreas.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Heading('Focus areas', kBodyAmber),
            for (final m in focusAreas.take(4)) _Row(status: m, color: kBodyAmber, onTap: () => onSelect(m)),
          ],
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Heading('Strengths', kBodyGreen),
            for (final m in strengths.take(4)) _Row(status: m, color: kBodyGreen, onTap: () => onSelect(m)),
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  final Color color;
  const _Heading(this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text.toUpperCase(),
              style: bodyText(10.5, color: color, weight: FontWeight.w800).copyWith(letterSpacing: 1)),
        ]),
      );
}

class _Row extends StatelessWidget {
  final MuscleStatus status;
  final Color color;
  final VoidCallback onTap;
  const _Row({required this.status, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(status.group.label, style: bodyText(14, weight: FontWeight.w700)),
                    if (status.pinned) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.push_pin_rounded, size: 12, color: color),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(muscleSuggestion(status), style: bodyText(12, color: kBodyMuted, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('${status.score}/10', style: bodyText(13, color: scoreColor(status.score), weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ── Muscle sheet ─────────────────────────────────────────────────────────────

/// One muscle group in detail, with the switch that makes it a focus area.
class MuscleFocusSheet extends StatefulWidget {
  final MuscleStatus status;
  final bool hasGoal;

  /// Pins or unpins the group; returns whether it saved.
  final Future<bool> Function(bool focus) onSetFocus;
  final VoidCallback onSetGoal;

  const MuscleFocusSheet({
    super.key,
    required this.status,
    required this.hasGoal,
    required this.onSetFocus,
    required this.onSetGoal,
  });

  @override
  State<MuscleFocusSheet> createState() => _MuscleFocusSheetState();
}

class _MuscleFocusSheetState extends State<MuscleFocusSheet> {
  late bool _pinned = widget.status.pinned;
  bool _busy = false;
  String? _error;

  Future<void> _toggle() async {
    if (!widget.hasGoal) {
      Navigator.of(context).pop();
      widget.onSetGoal();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await widget.onSetFocus(!_pinned);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _pinned = !_pinned;
      } else {
        _error = 'You can pin up to six muscles, or the change did not save.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    final color = levelColor(_pinned ? MuscleLevel.focus : s.level);
    final ratio = s.targetSets == 0 ? 0.0 : (s.weeklySets / s.targetSets).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Row(
            children: [
              Expanded(child: Text(s.group.label, style: bodyHeading(22))),
              StatusPill(label: _pinned ? 'Focus' : levelLabel(s.level), color: color),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${s.score}', style: bodyHeading(40, color: scoreColor(s.score))),
              Padding(
                padding: const EdgeInsets.only(bottom: 7, left: 4),
                child: Text('/ 10', style: bodyText(15, color: kBodyMuted, weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Weekly sets', style: bodyText(12.5, weight: FontWeight.w600)),
              const Spacer(),
              Text('${_n(s.weeklySets)} of about ${_n(s.targetSets)}',
                  style: bodyText(12.5, color: kBodyMuted)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: kBodyUntrained,
              color: scoreColor(s.score),
            ),
          ),
          const SizedBox(height: 14),
          if (s.strengthTrendPct != null)
            _Fact(
              icon: s.strengthTrendPct! >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: s.strengthTrendPct! >= 0 ? kBodyGreen : kBodyAmber,
              text: 'Strength ${s.strengthTrendPct! >= 0 ? 'up' : 'down'} ${_n(s.strengthTrendPct!.abs())}% '
                  'over four weeks',
            ),
          if (s.daysSinceTrained != null)
            _Fact(
              icon: Icons.schedule_rounded,
              color: kBodyMuted,
              text: s.daysSinceTrained == 0 ? 'Trained today' : 'Last trained ${s.daysSinceTrained} days ago',
            ),
          const SizedBox(height: 6),
          Text(s.reason, style: bodyText(13, color: Colors.white.withValues(alpha: 0.82), height: 1.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kBodyRaised, borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 16, color: kBodyLime),
                const SizedBox(width: 10),
                Expanded(child: Text(muscleSuggestion(s), style: bodyText(12.5, height: 1.45))),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: bodyText(12, color: kBodyRed)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: BodyButton(
              label: !widget.hasGoal
                  ? 'Set a goal to pin this'
                  : _pinned
                      ? 'Remove focus area'
                      : 'Set as focus area',
              icon: _pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              filled: !_pinned,
              busy: _busy,
              onPressed: _toggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Fact({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: bodyText(12.5, color: Colors.white.withValues(alpha: 0.85)))),
        ]),
      );
}
