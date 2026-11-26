import 'dart:math' as math;

import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

typedef SiteSummary = ({double latestCm, double? changeCm});

/// Sites that should get smaller on a cut; the rest should get bigger.
const _narrowing = {MeasurementSite.waist, MeasurementSite.hips, MeasurementSite.neck};

class MeasurementsCard extends StatelessWidget {
  final Map<MeasurementSite, SiteSummary> summary;
  final bool imperial;
  final GoalType? goalType;
  final ValueChanged<bool> onUnitChanged;
  final VoidCallback onLog;
  final ValueChanged<MeasurementSite> onTapSite;

  const MeasurementsCard({
    super.key,
    required this.summary,
    required this.imperial,
    required this.goalType,
    required this.onUnitChanged,
    required this.onLog,
    required this.onTapSite,
  });

  @override
  Widget build(BuildContext context) {
    final sites = [for (final s in MeasurementSite.values) if (summary.containsKey(s)) s];

    return BodyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Measurements',
            subtitle: sites.isEmpty
                ? 'Muscle and fat changes the scale can hide'
                : 'Change since your first reading',
            trailing: UnitToggle(
              imperial: imperial,
              metric: 'cm',
              imperialLabel: 'in',
              onChanged: onUnitChanged,
            ),
          ),
          const SizedBox(height: 14),
          if (sites.isEmpty)
            Text(
              'Measure your chest, waist, arms and legs once a month. When the scale stalls, '
              'the tape often shows muscle going up and fat coming down.',
              style: bodyText(12.5, color: kBodyMuted, height: 1.5),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final w = (c.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final s in sites)
                      SizedBox(
                        width: w,
                        child: _Tile(
                          site: s,
                          data: summary[s]!,
                          imperial: imperial,
                          tone: _tone(s, summary[s]!.changeCm),
                          onTap: () => onTapSite(s),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: BodyButton(label: 'Log measurements', icon: Icons.straighten_rounded, onPressed: onLog),
          ),
        ],
      ),
    );
  }

  Color _tone(MeasurementSite site, double? change) {
    if (change == null || change.abs() < 0.2) return kBodyMuted;
    final t = goalType;
    if (t == null || t == GoalType.maintain) return kBodyMuted;
    final wantsSmaller = _narrowing.contains(site) && t == GoalType.loseWeight;
    final wantsBigger = !_narrowing.contains(site) && (t == GoalType.buildMuscle || t == GoalType.gainWeight);
    if (!wantsSmaller && !wantsBigger) return kBodyMuted;
    final good = wantsSmaller ? change < 0 : change > 0;
    return good ? kBodyGreen : kBodyAmber;
  }
}

class _Tile extends StatelessWidget {
  final MeasurementSite site;
  final SiteSummary data;
  final bool imperial;
  final Color tone;
  final VoidCallback onTap;
  const _Tile({
    required this.site,
    required this.data,
    required this.imperial,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final change = data.changeCm;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: kBodyRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBodyBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(site.label, style: bodyText(11.5, color: kBodyMuted)),
            const SizedBox(height: 4),
            Text(BodyUnits.length(data.latestCm, imperial: imperial), style: bodyHeading(17)),
            const SizedBox(height: 6),
            if (change == null)
              Text('First reading', style: bodyText(11, color: kBodyMuted))
            else
              Row(
                children: [
                  Icon(
                    change.abs() < 0.2
                        ? Icons.remove_rounded
                        : change > 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                    size: 13,
                    color: tone,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    change.abs() < 0.2
                        ? 'No change'
                        : BodyUnits.length(change.abs(), imperial: imperial),
                    style: bodyText(11.5, color: tone, weight: FontWeight.w700),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// One site's readings over time, with a way to remove a mistaken one.
class MeasurementHistorySheet extends StatefulWidget {
  final MeasurementSite site;

  /// Oldest first.
  final List<BodyMeasurement> entries;
  final bool imperial;
  final Future<void> Function(BodyMeasurement) onDelete;

  const MeasurementHistorySheet({
    super.key,
    required this.site,
    required this.entries,
    required this.imperial,
    required this.onDelete,
  });

  @override
  State<MeasurementHistorySheet> createState() => _MeasurementHistorySheetState();
}

class _MeasurementHistorySheetState extends State<MeasurementHistorySheet> {
  late List<BodyMeasurement> _entries = [...widget.entries];

  double _v(double cm) => widget.imperial ? BodyUnits.cmToIn(cm) : cm;

  @override
  Widget build(BuildContext context) {
    final newestFirst = _entries.reversed.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Text(widget.site.label, style: bodyHeading(20)),
          const SizedBox(height: 4),
          Text('${_entries.length} ${_entries.length == 1 ? 'reading' : 'readings'}',
              style: bodyText(12, color: kBodyMuted)),
          if (_entries.length >= 2) ...[
            const SizedBox(height: 16),
            SizedBox(height: 120, child: _chart()),
          ],
          const SizedBox(height: 14),
          for (final e in newestFirst.take(12))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(shortDate(e.date), style: bodyText(13, color: kBodyMuted))),
                  Text(BodyUnits.length(e.valueCm, imperial: widget.imperial),
                      style: bodyText(14, weight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Delete reading',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 18, color: kBodyMuted),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await widget.onDelete(e);
                      if (!mounted) return;
                      setState(() => _entries = [for (final o in _entries) if (o != e) o]);
                      if (_entries.isEmpty) navigator.maybePop();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chart() {
    final first = _entries.first.date;
    final spots = [
      for (final e in _entries) FlSpot(e.date.difference(first).inDays.toDouble(), _v(e.valueCm))
    ];
    final lo = spots.map((s) => s.y).reduce(math.min), hi = spots.map((s) => s.y).reduce(math.max);
    final pad = math.max((hi - lo) * 0.25, 0.5);
    return LineChart(LineChartData(
      minY: lo - pad,
      maxY: hi + pad,
      minX: 0,
      maxX: math.max(spots.last.x, 1),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: kBodyBlue,
          barWidth: 3,
          dotData: FlDotData(
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3.5, color: kBodyBlue, strokeWidth: 0),
          ),
        ),
      ],
    ));
  }
}
