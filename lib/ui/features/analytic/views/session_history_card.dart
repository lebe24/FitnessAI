import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/session_volume.dart';
import 'package:fitness/domain/models/volume_format.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _kBadge = Color(0xFF1B2030);

/// The title a session is shown under. Only `dayLabel` names a session, and it
/// is often a weekday or blank, so there is always a fallback.
String sessionTitle(WorkoutSessionModel s) {
  final label = s.dayLabel?.trim();
  return label == null || label.isEmpty ? 'Session' : label;
}

/// `Thu, Nov 20`.
String sessionDateText(DateTime d) => DateFormat('EEE, MMM d', 'en_US').format(d);

/// One session in the history list: when, what, and three numbers.
class SessionHistoryCard extends StatefulWidget {
  final WorkoutSessionModel session;
  final bool imperial;
  final VoidCallback onTap;

  const SessionHistoryCard({
    super.key,
    required this.session,
    required this.imperial,
    required this.onTap,
  });

  @override
  State<SessionHistoryCard> createState() => _SessionHistoryCardState();
}

class _SessionHistoryCardState extends State<SessionHistoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final v = SessionVolume.fromSession(widget.session);
    final title = sessionTitle(widget.session);
    final date = sessionDateText(v.date);

    final stats = <_StatData>[
      if (v.durationMins > 0) _StatData(Icons.timer_outlined, '${v.durationMins} min'),
      if (v.exerciseCount > 0)
        _StatData(Icons.fitness_center_rounded, '${v.exerciseCount} ${v.exerciseCount == 1 ? 'exercise' : 'exercises'}'),
      if (v.hasVolume) _StatData(Icons.scale_rounded, formatVolume(v.totalVolumeKg, imperial: widget.imperial)),
    ];

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$title, $date. ${stats.map((s) => s.text).join(', ')}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: kBodyCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kBodyBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _kBadge, borderRadius: BorderRadius.circular(9)),
                      child: Text('SESSION',
                          style: bodyText(9, color: kBodyLime, weight: FontWeight.w700).copyWith(letterSpacing: 0.5)),
                    ),
                    const Spacer(),
                    Text(date, style: bodyText(12, color: kBodyMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyHeading(18)),
                const SizedBox(height: 14),
                if (stats.isEmpty)
                  Text('No sets were saved', style: bodyText(12, color: kBodyMuted))
                else
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [for (final s in stats) _Stat(s)],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String text;
  const _StatData(this.icon, this.text);
}

class _Stat extends StatelessWidget {
  final _StatData data;
  const _Stat(this.data);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(data.icon, size: 16, color: kBodyLime),
        const SizedBox(width: 6),
        Text(data.text, style: bodyText(12, color: kBodySoft)),
      ],
    );
  }
}
