import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/muscle_map/views/body_figure.dart';
import 'package:flutter/material.dart';

/// Choose a goal: its type, a target weight and pace, and the muscles to
/// prioritise.
class GoalSetupPage extends StatefulWidget {
  final FitnessGoal? initial;

  /// The latest weigh-in, used as the starting weight.
  final double? currentKg;
  final bool imperial;

  /// A muscle to start with pinned, when the user came from its sheet.
  final MuscleGroup? preselect;

  /// Saves the goal. Returns whether it worked.
  final Future<bool> Function(FitnessGoal goal) onSave;

  /// Removes the current goal. Null hides the button.
  final Future<bool> Function()? onClear;

  const GoalSetupPage({
    super.key,
    required this.initial,
    required this.currentKg,
    required this.imperial,
    required this.onSave,
    this.onClear,
    this.preselect,
  });

  @override
  State<GoalSetupPage> createState() => _GoalSetupPageState();
}

class _GoalSetupPageState extends State<GoalSetupPage> {
  late GoalType _type = widget.initial?.type ?? GoalType.loseWeight;
  late final Set<MuscleGroup> _focus = {
    ...?widget.initial?.focusMuscles,
    if (widget.preselect != null) widget.preselect!,
  };
  late final _current = TextEditingController(text: _fmt(widget.initial?.startWeightKg ?? widget.currentKg));
  late final _target = TextEditingController(text: _fmt(widget.initial?.targetWeightKg));
  late double? _rate = widget.initial?.weeklyRateKg;
  String? _error;
  bool _busy = false;
  BodyMap? _map;

  String _fmt(double? kg) {
    if (kg == null) return '';
    final v = widget.imperial ? BodyUnits.kgToLb(kg) : kg;
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  void initState() {
    super.initState();
    BodyMapSource.load().then((m) {
      if (mounted) setState(() => _map = m);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _current.dispose();
    _target.dispose();
    super.dispose();
  }

  double? _kgFrom(TextEditingController c) {
    final v = parseNumber(c.text);
    if (v == null) return null;
    return widget.imperial ? BodyUnits.lbToKg(v) : v;
  }

  double? get _currentKg => _kgFrom(_current);
  double? get _targetKg => _kgFrom(_target);

  double get _maxRate => GoalMath.maxWeeklyRateKg(_currentKg ?? widget.currentKg ?? 80);

  double get _effectiveRate {
    final bw = _currentKg ?? widget.currentKg ?? 80;
    final planned = _rate ?? GoalMath.plannedRateKg(_type, bw, null) ?? 0.4;
    return planned.clamp(0.1, _maxRate < 0.1 ? 0.1 : _maxRate).toDouble();
  }

  /// "About 12 weeks, around 14 Feb", or null when it cannot be worked out.
  String? get _projection {
    final cur = _currentKg, tgt = _targetKg;
    if (!_type.needsTarget || cur == null || tgt == null) return null;
    final remaining = (tgt - cur).abs();
    if (remaining == 0) return null;
    final weeks = (remaining / _effectiveRate).ceil();
    final date = DateTime.now().add(Duration(days: weeks * 7));
    return 'About $weeks ${weeks == 1 ? 'week' : 'weeks'}, around ${shortDate(date)}';
  }

  Future<void> _save() async {
    final cur = _currentKg, tgt = _targetKg;
    if (_type.needsTarget) {
      if (cur == null || cur < 20 || cur > 400) {
        return setState(() => _error = 'Enter your current weight.');
      }
      if (tgt == null || tgt < 20 || tgt > 400) {
        return setState(() => _error = 'Enter your target weight.');
      }
      if (_type == GoalType.loseWeight && tgt >= cur) {
        return setState(() => _error = 'A weight-loss target needs to be below your current weight.');
      }
      if (_type == GoalType.gainWeight && tgt <= cur) {
        return setState(() => _error = 'A weight-gain target needs to be above your current weight.');
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final goal = FitnessGoal(
      id: widget.initial?.id,
      type: _type,
      startWeightKg: cur,
      targetWeightKg: _type.needsTarget ? tgt : null,
      weeklyRateKg: _type.needsTarget ? double.parse(_effectiveRate.toStringAsFixed(2)) : null,
      focusMuscles: _focus.toList(),
    );
    final ok = await widget.onSave(goal);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = 'Could not save your goal. Check your connection and try again.';
      });
    }
  }

  Future<void> _clear() async {
    setState(() => _busy = true);
    final ok = await widget.onClear!();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = 'Could not remove the goal. Check your connection.';
      });
    }
  }

  void _toggle(MuscleGroup g) {
    setState(() {
      if (_focus.contains(g)) {
        _focus.remove(g);
      } else if (_focus.length < 6) {
        _focus.add(g);
      }
    });
  }

  MuscleGroup? _groupOf(String slug) => MuscleGroup.forSlug(slug);

  @override
  Widget build(BuildContext context) {
    final unit = widget.imperial ? 'lb' : 'kg';
    return Scaffold(
      backgroundColor: kBodyBg,
      appBar: AppBar(
        backgroundColor: kBodyCard,
        elevation: 0,
        title: Text(widget.initial == null ? 'Set your goal' : 'Edit your goal', style: bodyHeading(18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Text('What do you want to do?', style: bodyHeading(16)),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // A fixed height, so larger text sizes do not push the label out.
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 104,
            ),
            children: [for (final t in GoalType.values) _TypeTile(type: t, selected: t == _type, onTap: () => setState(() => _type = t))],
          ),
          if (_type.needsTarget) ...[
            const SizedBox(height: 22),
            Text('Your weight', style: bodyHeading(16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BodyField(
                    controller: _current,
                    label: 'Now',
                    suffix: unit,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BodyField(
                    controller: _target,
                    label: 'Target',
                    suffix: unit,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _PaceSlider(
              type: _type,
              value: _effectiveRate,
              max: _maxRate < 0.15 ? 0.15 : _maxRate,
              imperial: widget.imperial,
              projection: _projection,
              onChanged: (v) => setState(() => _rate = v),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              _type == GoalType.buildMuscle
                  ? 'Your coach will aim for slow, lean gains: about 250 extra calories a day, with training and measurements as the guide.'
                  : 'Your coach will keep your weight steady and your training progressing.',
              style: bodyText(13, color: kBodyMuted, height: 1.5),
            ),
          ],
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(child: Text('Muscles to prioritise', style: bodyHeading(16))),
              Text('${_focus.length}/6', style: bodyText(12.5, color: kBodyMuted, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Your coach adds work for these first. Tap the body or the chips.',
              style: bodyText(12.5, color: kBodyMuted)),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: _map == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kBodyLime))
                : Row(children: [
                    Expanded(child: _figure(_map!.front)),
                    const SizedBox(width: 8),
                    Expanded(child: _figure(_map!.back)),
                  ]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in MuscleGroup.values)
                _FocusChip(group: g, selected: _focus.contains(g), onTap: () => _toggle(g)),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: bodyText(13, color: kBodyRed, height: 1.4)),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: BodyButton(label: 'Save goal', busy: _busy, onPressed: _save)),
          if (widget.onClear != null) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _clear,
                child: Text('Remove this goal', style: bodyText(13, color: kBodyMuted, weight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _figure(BodyView view) => BodyFigure(
        view: view,
        onSelect: (slug) {
          final g = _groupOf(slug);
          if (g != null) _toggle(g);
        },
        fillFor: (slug) {
          final g = _groupOf(slug);
          return g != null && _focus.contains(g) ? kBodyAmber : null;
        },
        muscleColor: kBodyUntrained,
        silhouetteColor: const Color(0xFF1B2030),
        outlineColor: kBodyBg,
      );
}

class _TypeTile extends StatelessWidget {
  final GoalType type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeTile({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      GoalType.loseWeight => Icons.trending_down_rounded,
      GoalType.gainWeight => Icons.trending_up_rounded,
      GoalType.buildMuscle => Icons.fitness_center_rounded,
      GoalType.maintain => Icons.balance_rounded,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: type.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? kBodyLime.withValues(alpha: 0.12) : kBodyCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? kBodyLime : kBodyBorder, width: selected ? 1.5 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: selected ? kBodyLime : kBodyMuted),
              const SizedBox(height: 8),
              Text(type.label, style: bodyText(13.5, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaceSlider extends StatelessWidget {
  final GoalType type;
  final double value;
  final double max;
  final bool imperial;
  final String? projection;
  final ValueChanged<double> onChanged;
  const _PaceSlider({
    required this.type,
    required this.value,
    required this.max,
    required this.imperial,
    required this.projection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final verb = type == GoalType.loseWeight ? 'Lose' : 'Gain';
    final v = value.clamp(0.1, max).toDouble();
    final pct = max <= 0.1 ? 1.0 : (v - 0.1) / (max - 0.1);
    final note = pct > 0.8 ? 'Fast. Hard to keep up.' : pct < 0.3 ? 'Gentle and easy to sustain.' : 'A steady, sustainable pace.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How fast?', style: bodyHeading(16)),
        const SizedBox(height: 6),
        Text('$verb ${BodyUnits.weight(v, imperial: imperial)} a week',
            style: bodyHeading(18, color: kBodyLime)),
        Slider(
          value: v,
          min: 0.1,
          max: max,
          divisions: ((max - 0.1) / 0.05).round().clamp(1, 40),
          activeColor: kBodyLime,
          inactiveColor: kBodyUntrained,
          onChanged: onChanged,
        ),
        Text(note, style: bodyText(12, color: kBodyMuted)),
        if (projection != null) ...[
          const SizedBox(height: 6),
          Text(projection!, style: bodyText(13, weight: FontWeight.w600)),
        ],
        const SizedBox(height: 6),
        Text('The top of this range is 1% of your body weight a week, the most that is safe to keep up.',
            style: bodyText(11.5, color: kBodyMuted, height: 1.4)),
      ],
    );
  }
}

class _FocusChip extends StatelessWidget {
  final MuscleGroup group;
  final bool selected;
  final VoidCallback onTap;
  const _FocusChip({required this.group, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${group.label}${selected ? ', focus area' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? kBodyAmber.withValues(alpha: 0.14) : kBodyCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? kBodyAmber : kBodyBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (selected) ...[const Icon(Icons.push_pin_rounded, size: 13, color: kBodyAmber), const SizedBox(width: 5)],
            Text(group.label,
                style: bodyText(12.5, color: selected ? kBodyAmber : Colors.white, weight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
