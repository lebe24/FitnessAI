import 'dart:math' as math;

import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// The Body Weight card on the Analytics tab: the current weight, a small trend
/// chart and where the goal stands. Tapping it opens the full body-weight page.
///
/// Free users see the single weight they entered and a quiet note about what
/// Pro adds. Pro users see the chart drawn from their weigh-ins.
class BodyWeightCard extends StatelessWidget {
  /// Whether the user has body tracking. Free users get no chart.
  final bool pro;

  /// The weight to show, in kilograms: the latest weigh-in, or the single
  /// weight the older card kept.
  final double? kg;

  /// Weigh-ins, oldest first.
  final List<BodyWeightEntry> weights;
  final GoalProgress? progress;
  final double? targetKg;
  final bool imperial;
  final ValueChanged<bool> onUnitChanged;
  final DateTime? now;

  /// Opens the page, or the paywall for a free user.
  final VoidCallback onOpen;

  /// A quick way to enter a weight without opening the page.
  final VoidCallback onQuickLog;

  const BodyWeightCard({
    super.key,
    required this.pro,
    required this.kg,
    required this.weights,
    required this.progress,
    required this.targetKg,
    required this.imperial,
    required this.onUnitChanged,
    required this.onOpen,
    required this.onQuickLog,
    this.now,
  });

  /// How far back the small chart looks.
  static const _windowDays = 30;

  @override
  Widget build(BuildContext context) {
    final recent = _recent();
    return BodyCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Body Weight', style: bodyHeading(16))),
              if (!pro) ...[const PremiumBadge(visible: true), const SizedBox(width: 8)],
              UnitToggle(imperial: imperial, onChanged: onUnitChanged),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(weightText(kg, imperial), style: bodyHeading(28)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _Subline(progress: pro ? progress : null, imperial: imperial, hasWeight: kg != null)),
              _EditButton(onTap: onQuickLog),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 84,
            child: pro && recent.length >= 2
                ? _Sparkline(points: recent, targetKg: targetKg, imperial: imperial)
                : _NoChart(pro: pro, hasAny: weights.isNotEmpty),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  pro ? 'Goal, trend and measurements' : 'Track a goal and see your trend',
                  style: bodyText(12, color: kBodyMuted),
                ),
              ),
              Icon(pro ? Icons.arrow_forward_rounded : Icons.lock_rounded, size: 15, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  List<BodyWeightEntry> _recent() {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return [
      for (final w in weights)
        if (today.difference(w.date).inDays <= _windowDays) w
    ];
  }
}

/// Goal status, or the weekly pace, next to the weight.
class _Subline extends StatelessWidget {
  final GoalProgress? progress;
  final bool imperial;
  final bool hasWeight;
  const _Subline({required this.progress, required this.imperial, required this.hasWeight});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    if (p == null || p.goal == null) {
      return Text(
        hasWeight ? 'Latest weigh-in' : 'Not set yet',
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: bodyText(12, color: kBodyMuted),
      );
    }
    final weekly = p.trend.weeklyKg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        StatusPill(label: statusLabel(p.status), color: statusColor(p.status)),
        if (weekly != null) ...[
          const SizedBox(height: 3),
          Text('${signedWeight(weekly, imperial)} / wk',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyText(11, color: kBodyMuted)),
        ],
      ],
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Log weight',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 10),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: kBodyLime.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: kBodyLime.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.edit_rounded, size: 15, color: kBodyLime),
        ),
      ),
    );
  }
}

/// The trend with no axes: the shape of the last month, and the target.
class _Sparkline extends StatelessWidget {
  final List<BodyWeightEntry> points;
  final double? targetKg;
  final bool imperial;
  const _Sparkline({required this.points, required this.targetKg, required this.imperial});

  double _show(double kg) => imperial ? BodyUnits.kgToLb(kg) : kg;

  @override
  Widget build(BuildContext context) {
    final first = points.first.date;
    final spots = [
      for (final e in points) FlSpot(e.date.difference(first).inDays.toDouble(), _show(e.weightKg)),
    ];
    final target = targetKg == null ? null : _show(targetKg!);
    final ys = [for (final s in spots) s.y];
    final lo = ys.reduce(math.min), hi = ys.reduce(math.max);
    // The target only joins the scale when it is close; a far goal would
    // flatten the line.
    final span = math.max(hi - lo, 1.0);
    final showTarget = target != null && target >= lo - span * 2 && target <= hi + span * 2;
    final yMin = math.min(lo, showTarget ? target : lo);
    final yMax = math.max(hi, showTarget ? target : hi);
    final pad = math.max((yMax - yMin) * 0.15, 0.4);

    return IgnorePointer(
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(spots.last.x, 1),
          minY: yMin - pad,
          maxY: yMax + pad,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          extraLinesData: ExtraLinesData(horizontalLines: [
            if (showTarget)
              HorizontalLine(
                y: target,
                color: kBodyAmber.withValues(alpha: 0.7),
                strokeWidth: 1.2,
                dashArray: [4, 4],
              ),
          ]),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: kBodyLime,
              barWidth: 2.5,
              dotData: FlDotData(
                show: spots.length <= 14,
                getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(radius: 3, color: kBodyLime, strokeWidth: 0),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kBodyLime.withValues(alpha: 0.16), kBodyLime.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoChart extends StatelessWidget {
  final bool pro;
  final bool hasAny;
  const _NoChart({required this.pro, required this.hasAny});

  @override
  Widget build(BuildContext context) {
    final text = !pro
        ? 'Pro draws your weight over time'
        : hasAny
            ? 'One more weigh-in draws your line'
            : 'Log your weight to see your trend';
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(color: kBodyBg, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: bodyText(12, color: kBodyMuted)),
    );
  }
}
