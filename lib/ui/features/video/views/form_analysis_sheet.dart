import 'dart:math' as math;

import 'package:fitness/data/services/analytics/video_analytics.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/ui/features/video/views/video_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The rating for one clip: overall ring, stance / form / tempo bars, what it
/// could not judge, cues by importance, and what was good.
///
/// [onRerun] adds a "Re-run" action (it costs one of the month's analyses, so
/// the caller decides whether to offer it).
Future<void> showFormAnalysisSheet(
  BuildContext context, {
  required ExerciseVideo video,
  required FormAnalysis analysis,
  VoidCallback? onRerun,
}) {
  return showVideoSheet<void>(
    context,
    builder: (context) => FormAnalysisView(
      exerciseName: video.exerciseName,
      analysis: analysis,
      onRerun: onRerun == null
          ? null
          : () {
              Navigator.of(context).pop();
              onRerun();
            },
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}

/// The sheet's content, separate from the sheet chrome so it can be tested.
class FormAnalysisView extends StatefulWidget {
  final String exerciseName;
  final FormAnalysis analysis;
  final VoidCallback? onRerun;
  final VoidCallback onClose;

  const FormAnalysisView({
    super.key,
    required this.exerciseName,
    required this.analysis,
    required this.onClose,
    this.onRerun,
  });

  @override
  State<FormAnalysisView> createState() => _FormAnalysisViewState();
}

class _FormAnalysisViewState extends State<FormAnalysisView> {
  @override
  void initState() {
    super.initState();
    VideoAnalytics.resultViewed(widget.analysis);
  }

  static String _view(CameraView v) => switch (v) {
        CameraView.side => 'Filmed from the side',
        CameraView.front => 'Filmed from the front',
        CameraView.rear => 'Filmed from behind',
        CameraView.angled => 'Filmed at an angle',
        CameraView.unclear => 'Camera angle unclear',
      };

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    final cues = [...a.cues]..sort((x, y) => x.severity.index.compareTo(y.severity.index));
    final lowConfidence = a.confidence == Confidence.low;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a.exercise.isNotEmpty && !a.exerciseMatchesRequest ? a.exercise : widget.exerciseName,
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text('Form check',
              style: GoogleFonts.inter(fontSize: 13, color: kVideoDim)),
          if (!a.exerciseMatchesRequest) ...[
            const SizedBox(height: 14),
            _Note(
              icon: Icons.help_outline_rounded,
              color: kVideoAmber,
              text: a.exercise.isEmpty
                  ? "This doesn't look like ${widget.exerciseName}, so treat the rating with care."
                  : 'This looks like ${a.exercise}, not ${widget.exerciseName}, so treat the rating with care.',
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _Ring(score: a.overallScore),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.band ?? 'Not rated',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(_view(a.cameraView),
                        style: GoogleFonts.inter(fontSize: 13, color: kVideoDim)),
                    const SizedBox(height: 8),
                    _ConfidencePill(confidence: a.confidence),
                  ],
                ),
              ),
            ],
          ),
          if (lowConfidence) ...[
            const SizedBox(height: 14),
            const _Note(
              icon: Icons.info_outline_rounded,
              color: kVideoAmber,
              text: 'Low confidence: the angle or the footage limits what can be '
                  'judged. For a firmer rating, film side-on.',
            ),
          ],
          if (a.summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(a.summary,
                style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.white70)),
          ],
          const SizedBox(height: 22),
          _ScoreRow(label: 'Stance', score: a.stanceScore, notes: a.stance),
          _ScoreRow(label: 'Form', score: a.formScore, notes: a.form),
          _ScoreRow(label: 'Tempo', score: a.tempoScore, notes: a.tempo),
          if (a.repsCompleted != null || a.repAttempts != null) ...[
            const SizedBox(height: 8),
            _RepsCard(analysis: a),
          ],
          if (cues.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _Heading('What to work on'),
            const SizedBox(height: 10),
            for (final c in cues) _CueCard(cue: c),
          ],
          if (a.goodPoints.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _Heading('What looked good'),
            const SizedBox(height: 10),
            for (final g in a.goodPoints) _Bullet(g, color: kVideoLime, icon: Icons.check_rounded),
          ],
          if (a.limitations.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _Heading("What I couldn't judge"),
            const SizedBox(height: 10),
            for (final l in a.limitations)
              _Bullet(l, color: Colors.white38, icon: Icons.remove_rounded),
          ],
          const SizedBox(height: 24),
          if (widget.onRerun != null) ...[
            VideoSecondaryButton(
                label: 'Run again', icon: Icons.refresh_rounded, onTap: widget.onRerun),
            const SizedBox(height: 10),
          ],
          VideoPrimaryButton(label: 'Done', onTap: widget.onClose),
          const SizedBox(height: 14),
          Text(
            'General fitness guidance, not medical advice. Ratings come from a few '
            'still frames and can be wrong.',
            style: GoogleFonts.inter(fontSize: 11.5, height: 1.5, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────────────

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white));
}

class _Note extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Note({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: Colors.white70)),
            ),
          ],
        ),
      );
}

class _ConfidencePill extends StatelessWidget {
  final Confidence confidence;
  const _ConfidencePill({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (confidence) {
      Confidence.high => ('High confidence', kVideoLime),
      Confidence.medium => ('Medium confidence', kVideoAmber),
      Confidence.low => ('Low confidence', kVideoRed),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _Ring extends StatelessWidget {
  final int? score;
  const _Ring({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);
    return Semantics(
      label: score == null ? 'Not rated' : 'Overall rating $score out of 10',
      excludeSemantics: true,
      child: SizedBox(
        width: 92,
        height: 92,
        child: CustomPaint(
          painter: _RingPainter(fraction: (score ?? 0) / 10, color: color),
          child: Center(
            child: score == null
                ? Text('—',
                    style: GoogleFonts.poppins(fontSize: 26, color: Colors.white38))
                : RichText(
                    text: TextSpan(
                      text: '$score',
                      style: GoogleFonts.poppins(
                          fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
                      children: [
                        TextSpan(
                          text: '/10',
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  const _RingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawArc(arc, 0, math.pi * 2, false, track);
    if (fraction <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = color;
    canvas.drawArc(arc, -math.pi / 2, math.pi * 2 * fraction.clamp(0.0, 1.0), false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.color != color;
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int? score;
  final List<String> notes;
  const _ScoreRow({required this.label, required this.score, required this.notes});

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(width: 12),
              // Flexible, so on a narrow phone or large text the words wrap
              // instead of running off the edge.
              Flexible(
                child: Text(score == null ? "Can't judge from this angle" : '$score/10',
                    textAlign: TextAlign.end,
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: score == null ? Colors.white38 : color)),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score ?? 0) / 10,
              minHeight: 7,
              color: color,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(n,
                  style: GoogleFonts.inter(fontSize: 12.5, height: 1.4, color: kVideoDim)),
            ),
        ],
      ),
    );
  }
}

class _RepsCard extends StatelessWidget {
  final FormAnalysis analysis;
  const _RepsCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    final parts = <String>[
      if (a.repsCompleted != null)
        '${a.repsCompleted} clean ${a.repsCompleted == 1 ? 'rep' : 'reps'}',
      if (a.repAttempts != null)
        '${a.repAttempts} ${a.repAttempts == 1 ? 'attempt' : 'attempts'}',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kVideoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kVideoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.repeat_rounded, size: 16, color: kVideoLime),
              const SizedBox(width: 8),
              Expanded(
                child: Text(parts.join(' · '),
                    style: GoogleFonts.inter(
                        fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
          if (a.repNotes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(a.repNotes,
                style: GoogleFonts.inter(fontSize: 12.5, height: 1.4, color: kVideoDim)),
          ],
        ],
      ),
    );
  }
}

class _CueCard extends StatelessWidget {
  final FormCue cue;
  const _CueCard({required this.cue});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (cue.severity) {
      CueSeverity.high => ('Important', kVideoRed),
      CueSeverity.medium => ('Worth fixing', kVideoAmber),
      CueSeverity.low => ('Minor', Colors.white54),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kVideoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: color)),
          const SizedBox(height: 5),
          Text(cue.issue,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          if (cue.fix.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(cue.fix,
                style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _Bullet(this.text, {required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.inter(fontSize: 13.5, height: 1.45, color: Colors.white70)),
            ),
          ],
        ),
      );
}
