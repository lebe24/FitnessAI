import 'dart:async';

import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/data/services/video/form_analysis_runner.dart';
import 'package:fitness/data/services/video/form_analysis_service.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/video/views/video_flow.dart';
import 'package:fitness/ui/features/video/views/video_sheets.dart';
import 'package:fitness/ui/features/video/views/video_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "My Videos" on the exercise page: the user's own recordings of this
/// movement, saved on the device, each with an optional AI form rating.
///
/// Named **My Videos** so it is never mistaken for the YouTube "Video
/// Tutorials" further down the page.
class ExerciseVideosSection extends StatefulWidget {
  final String exerciseName;

  /// Muscle slugs this exercise trains, saved with each new video.
  final List<String> muscles;
  final DateTime? workoutDate;
  final String? dayLabel;

  // Injectable for tests; they default to the app's own.
  final ExerciseVideoStorage? storage;
  final FormAnalysisRunner? runner;
  final bool Function()? analysisLocked;
  final Future<void> Function()? onAdd;
  final DateTime? now;

  const ExerciseVideosSection({
    super.key,
    required this.exerciseName,
    required this.muscles,
    this.workoutDate,
    this.dayLabel,
    this.storage,
    this.runner,
    this.analysisLocked,
    this.onAdd,
    this.now,
  });

  @override
  State<ExerciseVideosSection> createState() => _ExerciseVideosSectionState();
}

class _ExerciseVideosSectionState extends State<ExerciseVideosSection> {
  late final ExerciseVideoStorage _storage = widget.storage ?? sl<ExerciseVideoStorage>();
  late final FormAnalysisRunner _runner = widget.runner ?? sl<FormAnalysisRunner>();

  List<ExerciseVideo>? _videos; // null until the first read
  bool _adding = false;

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
    final videos = await _storage.forExercise(widget.exerciseName);
    if (mounted) setState(() => _videos = videos);
  }

  bool get _locked => widget.analysisLocked != null
      ? widget.analysisLocked!()
      : !sl<AccessPolicy>().canUse(PremiumFeature.formAnalysis);

  Future<void> _add() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      if (widget.onAdd != null) {
        await widget.onAdd!();
      } else {
        await addVideoFlow(
          context,
          exerciseName: widget.exerciseName,
          muscles: widget.muscles,
          workoutDate: widget.workoutDate,
          dayLabel: widget.dayLabel,
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videos = _videos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.videocam_outlined, size: 18, color: kVideoLime),
            const SizedBox(width: 8),
            Text('My Videos',
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
            const Spacer(),
            if (videos != null && videos.isNotEmpty) ...[
              TextButton(
                onPressed: () => showRecordingTips(context),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32)),
                child: Text('Tips',
                    style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white54)),
              ),
              TextButton.icon(
                onPressed: _adding ? null : _add,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32)),
                icon: const Icon(Icons.add_rounded, size: 18, color: kVideoLime),
                label: Text('Add',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: kVideoLime)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (videos == null)
          const SizedBox(height: 40)
        else if (videos.isEmpty)
          _Empty(onAdd: _adding ? null : _add)
        else
          SizedBox(
            height: 262,
            child: ListenableBuilder(
              listenable: _runner,
              builder: (context, _) => ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: videos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => VideoCard(
                  video: videos[i],
                  storage: _storage,
                  runner: _runner,
                  locked: _locked,
                  now: widget.now ?? DateTime.now(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback? onAdd;
  const _Empty({required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kVideoCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kVideoBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record a set to check your form',
                style: GoogleFonts.inter(
                    fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              'Videos stay on this phone. You can get an AI rating of your stance, form and tempo.',
              style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: kVideoDim),
            ),
            const SizedBox(height: 14),
            VideoSecondaryButton(label: 'Add video', icon: Icons.videocam_rounded, onTap: onAdd),
          ],
        ),
      );
}

/// One saved video as a card: picture, length, date, and its rating or an
/// Analyse button. Watches its analysis job, so it shows progress and failure
/// without the page doing anything.
class VideoCard extends StatelessWidget {
  final ExerciseVideo video;
  final ExerciseVideoStorage storage;
  final FormAnalysisRunner runner;
  final bool locked;
  final DateTime now;

  const VideoCard({
    super.key,
    required this.video,
    required this.storage,
    required this.runner,
    required this.locked,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final job = runner.jobFor(video.id);
    final analysing = job != null && job.isRunning;
    final failed = job != null && job.phase == AnalysisPhase.failed;

    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: 'Play video from ${videoDate(video.recordedAt, now)}',
            child: GestureDetector(
              onTap: () => openVideo(context, video),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 140,
                  height: 186,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoThumbnail(video: video, storage: storage),
                      if (analysing)
                        ColoredBox(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    strokeWidth: 3, color: kVideoLime),
                              ),
                              const SizedBox(height: 10),
                              Text('Analysing…',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                              TextButton(
                                onPressed: () => runner.cancel(video.id),
                                style: TextButton.styleFrom(minimumSize: const Size(0, 28)),
                                child: Text('Cancel',
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                              ),
                            ],
                          ),
                        )
                      else
                        const Center(
                          child: Icon(Icons.play_circle_fill_rounded,
                              size: 34, color: Colors.white70),
                        ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(videoDuration(video.duration),
                              style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(videoDate(video.recordedAt, now),
              style: GoogleFonts.inter(fontSize: 12, color: kVideoDim)),
          const SizedBox(height: 6),
          if (analysing)
            const SizedBox.shrink()
          else if (video.isAnalysed)
            GestureDetector(
              onTap: () => openAnalysis(context, video.id),
              child: RatingChip(analysis: video.analysis!),
            )
          else if (failed)
            _RetryPill(error: job.error, onTap: () => analyseFlow(context, video))
          else
            _AnalysePill(locked: locked, onTap: () => analyseFlow(context, video)),
        ],
      ),
    );
  }
}

class _AnalysePill extends StatelessWidget {
  final bool locked;
  final VoidCallback onTap;
  const _AnalysePill({required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: locked ? 'Analyse form, Pro feature' : 'Analyse form',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kVideoLime.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kVideoLime.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(locked ? Icons.lock_outline_rounded : Icons.auto_awesome_rounded,
                    size: 12, color: kVideoLime),
                const SizedBox(width: 5),
                Text('Analyse',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700, color: kVideoLime)),
              ],
            ),
          ),
        ),
      );
}

class _RetryPill extends StatelessWidget {
  final FormAnalysisException? error;
  final VoidCallback onTap;
  const _RetryPill({required this.error, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final capped = error?.failure == FormAnalysisFailure.monthlyCap;
    return Semantics(
      button: true,
      label: capped ? 'Monthly limit reached' : 'Analysis failed, retry',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: capped ? () => videoSnack(context, analysisFailureMessage(error!), error: true) : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: kVideoRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kVideoRed.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(capped ? Icons.block_rounded : Icons.refresh_rounded,
                  size: 12, color: kVideoRed),
              const SizedBox(width: 5),
              Flexible(
                child: Text(capped ? 'Limit reached' : 'Retry',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700, color: kVideoRed)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
