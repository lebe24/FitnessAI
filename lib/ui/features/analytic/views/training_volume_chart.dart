import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/session_volume.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kCard = Color(0xFF111318);
const _kCard2 = Color(0xFF161B26);
const _kBorder = Color(0xFF1E2330);
const _kSub = Color(0x80FFFFFF);
const _kLime = Color(0xFFCCFF00);

/// Training volume per session, as bars.
///
/// Replaces the list of session tiles that sat here. A list answers "what did I
/// do on the 15th", which the session detail already answers; a chart answers
/// "am I doing more than I was", which nothing did. Volume — reps × weight,
/// summed — is the standard measure of how much work a session contained, and
/// it is the one number in this data that trends.
///
/// Bars rather than a line: sessions are discrete events on irregular dates,
/// not a continuous series. A line between two sessions nine days apart draws a
/// slope through days that never happened.
class TrainingVolumeChart extends StatelessWidget {
  final List<WorkoutSessionModel> sessions;
  final bool isLoading;

  /// Most recent N sessions, oldest first. Ten is about the limit before bars
  /// get too narrow to touch on a phone.
  final int maxBars;

  const TrainingVolumeChart({
    super.key,
    required this.sessions,
    required this.isLoading,
    this.maxBars = 8,
  });

  List<SessionVolume> get _data {
    final volumes = sessions
        .map(SessionVolume.fromSession)
        // Sessions with no measurable load would plot as empty gaps and read
        // as "you did nothing that day".
        .where((v) => v.hasVolume)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return volumes.length <= maxBars
        ? volumes
        : volumes.sublist(volumes.length - maxBars);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(data: data),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kLime),
                    ),
                  )
                : data.isEmpty
                    ? const _Empty()
                    : _Bars(data: data),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final List<SessionVolume> data;
  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (s, d) => s + d.totalVolumeKg);
    final sets = data.fold<int>(0, (s, d) => s + d.setCount);

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
          child: const Icon(Icons.bar_chart_rounded, size: 19, color: _kLime),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Training volume',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(
                data.isEmpty
                    ? 'Log a session to see your load'
                    : 'Last ${data.length} sessions · $sets sets',
                style: GoogleFonts.inter(fontSize: 11.5, color: _kSub),
              ),
            ],
          ),
        ),
        if (data.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                total >= 1000
                    ? '${(total / 1000).toStringAsFixed(1)}t'
                    : '${total.round()}kg',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kLime),
              ),
              Text('total moved',
                  style: GoogleFonts.inter(fontSize: 10, color: _kSub)),
            ],
          ),
      ],
    );
  }
}

class _Bars extends StatelessWidget {
  final List<SessionVolume> data;
  const _Bars({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVolume =
        data.map((d) => d.totalVolumeKg).reduce((a, b) => a > b ? a : b);
    // Headroom so the tallest bar is not flush with the top of the box.
    final maxY = maxVolume * 1.18;

    // The heaviest session is highlighted; the rest are dimmed. With eight
    // bars in a small box, a single accent reads faster than eight of them.
    final peak = data.indexWhere((d) => d.totalVolumeKg == maxVolume);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final d = data[i].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${d.day}/${d.month}',
                    style: GoogleFonts.inter(fontSize: 9.5, color: _kSub),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _kCard2,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = data[groupIndex];
              return BarTooltipItem(
                '${d.shortVolume}\n',
                GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kLime,
                ),
                children: [
                  TextSpan(
                    text: '${d.exerciseCount} exercises · ${d.setCount} sets',
                    style: GoogleFonts.inter(fontSize: 10.5, color: _kSub),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].totalVolumeKg,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                  ),
                  color: i == peak
                      ? _kLime
                      : _kLime.withValues(alpha: 0.28),
                  // A faint track behind each bar gives the eye a baseline to
                  // compare against when the values are close.
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 30, color: _kLime.withValues(alpha: 0.35)),
            const SizedBox(height: 10),
            Text('No volume logged yet',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Log sets with a weight to track your load',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11, color: _kSub)),
          ],
        ),
      );
}
