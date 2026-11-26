import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/domain/models/session_feedback.dart';
import 'package:fitness/domain/models/session_share.dart';
import 'package:fitness/domain/models/session_volume.dart';
import 'package:fitness/domain/models/volume_format.dart';
import 'package:fitness/ui/features/analytic/views/analytics_stat_tile.dart';
import 'package:fitness/ui/features/analytic/views/body/body_actions.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/analytic/views/session_history_card.dart';
import 'package:fitness/ui/features/analytic/views/share/session_share_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One logged session in full: the numbers, every exercise with its sets, and
/// the coach's feedback if one was saved. Opened from the history list.
class SessionDetailPage extends StatefulWidget {
  final WorkoutSessionModel session;
  final bool imperial;

  /// Every loaded session, used to mark new bests on the share picture.
  final List<WorkoutSessionModel> history;

  const SessionDetailPage({
    super.key,
    required this.session,
    required this.imperial,
    this.history = const [],
  });

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  @override
  void initState() {
    super.initState();
    Analytics.screen('workout_session');
  }

  WorkoutSessionModel get session => widget.session;
  bool get imperial => widget.imperial;

  void _share() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SessionSharePage(
        share: SessionShare.of(session, history: widget.history),
        imperial: imperial,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final v = SessionVolume.fromSession(session);
    final exercises = SessionVolume.exercisesOf(session);
    final feedback = SessionFeedback.fromMap(session.feedback);

    return BodyPageScaffold(
      // Nothing to put on a picture without any logged sets.
      floatingActionButton: v.setCount == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: _share,
              backgroundColor: kBodyLime,
              foregroundColor: kBodyBg,
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              label: Text('Share', style: bodyHeading(14, color: kBodyBg)),
            ),
      title: sessionTitle(session),
      subtitle: DateFormat('EEEE, MMMM d', 'en_US').format(v.date),
      children: [
        Row(children: [
          Expanded(
            child: AnalyticsStatTile(
              icon: Icons.timer_outlined,
              color: kBodyBlue,
              value: v.durationMins > 0 ? '${v.durationMins} min' : '–',
              label: 'Duration',
              sub: v.durationMins > 0 ? 'logged' : 'not recorded',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnalyticsStatTile(
              icon: Icons.fitness_center_rounded,
              color: kBodyLime,
              value: '${v.exerciseCount}',
              label: v.exerciseCount == 1 ? 'Exercise' : 'Exercises',
              sub: '${v.setCount} ${v.setCount == 1 ? 'set' : 'sets'}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnalyticsStatTile(
              icon: Icons.scale_rounded,
              color: kBodyAmber,
              value: v.hasVolume ? formatVolume(v.totalVolumeKg, imperial: imperial) : '–',
              label: 'Volume',
              sub: v.hasVolume ? 'total moved' : 'bodyweight only',
            ),
          ),
        ]),
        const SizedBox(height: 16),
        if (exercises.isEmpty)
          BodyCard(
            child: Text('No sets were saved for this session.',
                style: bodyText(13, color: kBodyMuted, height: 1.5)),
          )
        else
          for (final e in exercises) ...[
            _ExerciseCard(exercise: e, imperial: imperial),
            const SizedBox(height: 12),
          ],
        if (!feedback.isEmpty) ...[
          const SizedBox(height: 4),
          _FeedbackCard(feedback: feedback),
        ],
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseVolume exercise;
  final bool imperial;
  const _ExerciseCard({required this.exercise, required this.imperial});

  String _setLabel(LoggedSet s) {
    if (s.durationSec != null) return '${s.durationSec}s';
    final reps = s.reps ?? 0;
    final kg = s.weightKg;
    if (kg == null || kg == 0) return '$reps reps';
    return '$reps × ${formatSetWeight(kg, imperial: imperial)}';
  }

  @override
  Widget build(BuildContext context) {
    final top = exercise.topSet;
    final performed = exercise.performedSets;
    final bits = <String>[
      '$performed ${performed == 1 ? 'set' : 'sets'}',
      if (top != null) 'top ${formatSetWeight(top.weightKg!, imperial: imperial)}',
    ];

    return BodyCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(exercise.name, style: bodyText(14.5, weight: FontWeight.w700, height: 1.3))),
              if (exercise.volumeKg > 0) ...[
                const SizedBox(width: 10),
                Text(formatVolume(exercise.volumeKg, imperial: imperial),
                    style: bodyText(12, color: kBodyLime, weight: FontWeight.w700)),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(bits.join(' · '), style: bodyText(11.5, color: kBodyMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in exercise.sets)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    // A skipped set is dimmed rather than hidden: the gap in a
                    // session is information too.
                    color: s.wasPerformed ? kBodyLime.withValues(alpha: 0.09) : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: s.wasPerformed ? kBodyLime.withValues(alpha: 0.22) : kBodyBorder),
                  ),
                  child: Text(
                    s.wasPerformed ? _setLabel(s) : 'skipped',
                    style: bodyText(11, color: s.wasPerformed ? kBodyLime : Colors.white30, weight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final SessionFeedback feedback;
  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final f = feedback;
    final children = <Widget>[
      if (f.analysis != null) Text(f.analysis!, style: bodyText(13, color: kBodySoft, height: 1.55)),
      if (f.highlights.isNotEmpty) _Block('WENT WELL', f.highlights, kBodyGreen),
      if (f.improvements.isNotEmpty) _Block('TO IMPROVE', f.improvements, kBodyAmber),
      if (f.rest != null) _Note('REST', f.rest!),
      if (f.nextSessionTip != null) _Note('NEXT SESSION', f.nextSessionTip!),
      if (f.hasNutrition) _Nutrition(f),
    ];

    return BodyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, size: 16, color: kBodyLime),
            const SizedBox(width: 8),
            Text('Coach feedback', style: bodyHeading(16)),
          ]),
          for (final c in children) ...[const SizedBox(height: 14), c],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, this.color);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: bodyText(10.5, color: color, weight: FontWeight.w700).copyWith(letterSpacing: 0.7));
}

class _Block extends StatelessWidget {
  final String label;
  final List<String> items;
  final Color color;
  const _Block(this.label, this.items, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label, color),
        const SizedBox(height: 6),
        for (final i in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(i, style: bodyText(13, color: kBodySoft, height: 1.5))),
              ],
            ),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final String label;
  final String text;
  const _Note(this.label, this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label, kBodyBlue),
        const SizedBox(height: 6),
        Text(text, style: bodyText(13, color: kBodySoft, height: 1.5)),
      ],
    );
  }
}

class _Nutrition extends StatelessWidget {
  final SessionFeedback f;
  const _Nutrition(this.f);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kBodyBg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('AFTER THE SESSION', kBodyLime),
          if (f.proteinTargetG != null) ...[
            const SizedBox(height: 8),
            Text('Aim for about ${f.proteinTargetG} g of protein.', style: bodyText(13, weight: FontWeight.w600)),
          ],
          if (f.nutritionNow != null) ...[
            const SizedBox(height: 6),
            Text(f.nutritionNow!, style: bodyText(13, color: kBodySoft, height: 1.5)),
          ],
          if (f.meals.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(f.meals.join(' · '), style: bodyText(12.5, color: kBodyMuted, height: 1.5)),
          ],
          if (f.hydration != null) ...[
            const SizedBox(height: 6),
            Text(f.hydration!, style: bodyText(12.5, color: kBodyMuted, height: 1.5)),
          ],
          if (f.timingTip != null) ...[
            const SizedBox(height: 6),
            Text(f.timingTip!, style: bodyText(12.5, color: kBodyMuted, height: 1.5)),
          ],
        ],
      ),
    );
  }
}
