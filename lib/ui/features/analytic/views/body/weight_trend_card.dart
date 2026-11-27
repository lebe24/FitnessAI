import 'dart:math' as math;

import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum WeightRange {
  month('1M', 30),
  quarter('3M', 90),
  year('1Y', 365),
  all('All', 100000);

  const WeightRange(this.label, this.days);
  final String label;
  final int days;
}

/// Weigh-ins over time, with the target as a dashed line.
class WeightTrendCard extends StatefulWidget {
  /// Oldest first.
  final List<BodyWeightEntry> weights;
  final double? targetKg;
  final bool imperial;
  final DateTime now;
  final ValueChanged<bool> onUnitChanged;
  final VoidCallback onLog;

  const WeightTrendCard({
    super.key,
    required this.weights,
    required this.targetKg,
    required this.imperial,
    required this.now,
    required this.onUnitChanged,
    required this.onLog,
  });

  @override
  State<WeightTrendCard> createState() => _WeightTrendCardState();
}

class _WeightTrendCardState extends State<WeightTrendCard> {
  WeightRange _range = WeightRange.quarter;

  double _show(double kg) => widget.imperial ? BodyUnits.kgToLb(kg) : kg;

  List<BodyWeightEntry> get _visible {
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);
    return [
      for (final w in widget.weights)
        if (today.difference(w.date).inDays <= _range.days) w
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pts = _visible;
    final latest = widget.weights.isEmpty ? null : widget.weights.last;

    return BodyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Weight trend',
            subtitle: latest == null ? 'No weigh-ins yet' : 'Latest ${shortDate(latest.date)}',
            trailing: UnitToggle(imperial: widget.imperial, onChanged: widget.onUnitChanged),
          ),
          if (latest != null) ...[
            const SizedBox(height: 12),
            Text(weightText(latest.weightKg, widget.imperial),
                style: bodyHeading(26)),
          ],
          const SizedBox(height: 14),
          if (pts.length < 2)
            _Empty(onLog: widget.onLog, hasAny: widget.weights.isNotEmpty)
          else ...[
            SizedBox(height: 170, child: _chart(pts)),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final r in WeightRange.values) ...[
                  Expanded(child: _RangeChip(range: r, selected: r == _range, onTap: () => setState(() => _range = r))),
                  if (r != WeightRange.values.last) const SizedBox(width: 6),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chart(List<BodyWeightEntry> pts) {
    final first = pts.first.date;
    double x(BodyWeightEntry e) => e.date.difference(first).inDays.toDouble();
    final spots = [for (final e in pts) FlSpot(x(e), _show(e.weightKg))];

    final ys = [for (final s in spots) s.y, if (widget.targetKg != null) _show(widget.targetKg!)];
    final lo = ys.reduce(math.min), hi = ys.reduce(math.max);
    final pad = math.max((hi - lo) * 0.2, 0.5);
    final maxX = math.max(spots.last.x, 1.0);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: lo - pad,
        maxY: hi + pad,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: math.max((hi - lo + 2 * pad) / 3, 0.5),
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.06), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: math.max((hi - lo + 2 * pad) / 3, 0.5),
              getTitlesWidget: (v, meta) => v == meta.min || v == meta.max
                  ? const SizedBox.shrink()
                  : Text(v.toStringAsFixed(0), style: bodyText(10, color: kBodyMuted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: math.max((maxX / 3).roundToDouble(), 1),
              getTitlesWidget: (v, meta) => v == meta.max && maxX > 3
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(shortDate(first.add(Duration(days: v.round()))),
                          style: bodyText(10, color: kBodyMuted)),
                    ),
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          if (widget.targetKg != null)
            HorizontalLine(
              y: _show(widget.targetKg!),
              color: kBodyAmber.withValues(alpha: 0.7),
              strokeWidth: 1.5,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: bodyText(10, color: kBodyAmber, weight: FontWeight.w700),
                labelResolver: (_) => 'Target',
              ),
            ),
        ]),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => kBodyRaised,
            getTooltipItems: (items) => [
              for (final s in items)
                LineTooltipItem(
                  '${s.y.toStringAsFixed(1)} ${widget.imperial ? 'lb' : 'kg'}\n'
                  '${shortDate(first.add(Duration(days: s.x.round())))}',
                  bodyText(11.5, weight: FontWeight.w700),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: kBodyLime,
            barWidth: 3,
            dotData: FlDotData(
              show: spots.length <= 31,
              getDotPainter: (_, __, ___, ____) =>
                  FlDotCirclePainter(radius: 3.5, color: kBodyLime, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kBodyLime.withValues(alpha: 0.18), kBodyLime.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final WeightRange range;
  final bool selected;
  final VoidCallback onTap;
  const _RangeChip({required this.range, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kBodyLime.withValues(alpha: 0.14) : kBodyBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? kBodyLime.withValues(alpha: 0.4) : kBodyBorder),
        ),
        child: Text(range.label,
            style: bodyText(12, color: selected ? kBodyLime : kBodyMuted, weight: FontWeight.w700)),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onLog;
  final bool hasAny;
  const _Empty({required this.onLog, required this.hasAny});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: kBodyBg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasAny ? 'One more weigh-in in this range draws the line' : 'Log your weight to see your trend',
            textAlign: TextAlign.center,
            style: bodyText(12.5, color: kBodyMuted),
          ),
          const SizedBox(height: 12),
          BodyButton(label: 'Log weight', icon: Icons.add_rounded, onPressed: onLog),
        ],
      ),
    );
  }
}
