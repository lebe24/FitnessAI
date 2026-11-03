import 'package:fitness/data/services/analytics/video_analytics.dart';
import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/video/views/video_flow.dart';
import 'package:fitness/ui/features/video/views/video_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "My Videos" on a muscle's page (Stats → Muscles trained → a muscle): every
/// video saved against an exercise that trains it, newest first, with ratings
/// and, from three rated videos on, how the ratings are moving.
///
/// Reads the on-device index only, so it needs no network and works offline.
class MuscleVideosSection extends StatefulWidget {
  final Muscle muscle;
  final ExerciseVideoStorage? storage;
  final DateTime? now;

  const MuscleVideosSection({super.key, required this.muscle, this.storage, this.now});

  @override
  State<MuscleVideosSection> createState() => _MuscleVideosSectionState();
}

class _MuscleVideosSectionState extends State<MuscleVideosSection> {
  late final ExerciseVideoStorage _storage = widget.storage ?? sl<ExerciseVideoStorage>();
  List<ExerciseVideo>? _videos;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _storage.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _storage.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final videos = await _storage.forMuscle(widget.muscle.slug);
    if (!mounted) return;
    setState(() => _videos = videos);
    if (videos.isNotEmpty && !_reported) {
      _reported = true;
      VideoAnalytics.muscleVideosOpened(widget.muscle.slug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videos = _videos;
    if (videos == null) return const SizedBox(height: 24);
    if (videos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kVideoCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kVideoBorder),
        ),
        child: Text(
          'Videos you record against ${widget.muscle.name.toLowerCase()} exercises '
          'appear here, with their form ratings.',
          style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: kVideoDim),
        ),
      );
    }

    final now = widget.now ?? DateTime.now();
    final rated = [
      for (final v in videos.reversed)
        if (v.analysis?.overallScore != null) v.analysis!.overallScore!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rated.length >= 3) ...[
          _Trend(scores: rated),
          const SizedBox(height: 12),
        ],
        for (final v in videos)
          _VideoRow(video: v, storage: _storage, now: now),
      ],
    );
  }
}

class _VideoRow extends StatelessWidget {
  final ExerciseVideo video;
  final ExerciseVideoStorage storage;
  final DateTime now;
  const _VideoRow({required this.video, required this.storage, required this.now});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${video.exerciseName}, ${videoDate(video.recordedAt, now)}. Play video',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => openVideo(context, video),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kVideoCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kVideoBorder),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 84,
                  child: VideoThumbnail(video: video, storage: storage),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.exerciseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(
                      '${videoDate(video.recordedAt, now)} · ${videoDuration(video.duration)}',
                      style: GoogleFonts.inter(fontSize: 12.5, color: kVideoDim),
                    ),
                    const SizedBox(height: 8),
                    if (video.isAnalysed)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RatingChip(analysis: video.analysis!),
                      )
                    else
                      Text('Not analysed',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small line of the ratings over time, oldest to newest, with the change
/// since the first one in words.
class _Trend extends StatelessWidget {
  final List<int> scores;
  const _Trend({required this.scores});

  @override
  Widget build(BuildContext context) {
    final first = scores.first, last = scores.last;
    final change = last - first;
    final (label, color) = change > 0
        ? ('Up $change since your first rated video', kVideoLime)
        : change < 0
            ? ('Down ${-change} since your first rated video', kVideoAmber)
            : ('Steady since your first rated video', Colors.white70);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kVideoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kVideoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Form rating trend',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: CustomPaint(painter: _TrendPainter(scores, color)),
          ),
          const SizedBox(height: 8),
          Text('$first → $last · $label',
              style: GoogleFonts.inter(fontSize: 12.5, color: color)),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<int> scores;
  final Color color;
  const _TrendPainter(this.scores, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;
    double x(int i) => size.width * i / (scores.length - 1);
    double y(int s) => size.height - (s.clamp(1, 10) - 1) / 9 * size.height;

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(x(0), y(scores[0]));
    for (var i = 1; i < scores.length; i++) {
      path.lineTo(x(i), y(scores[i]));
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = color;
    for (var i = 0; i < scores.length; i++) {
      canvas.drawCircle(Offset(x(i), y(scores[i])), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.scores != scores || old.color != color;
}
