import 'dart:async';

import 'package:fitness/data/services/analytics/video_analytics.dart';
import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/data/services/video/form_analysis_runner.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/video/views/video_flow.dart';
import 'package:fitness/ui/features/video/views/video_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

/// Watch a saved video: play, pause, scrub, and slow motion (form is judged
/// frame by frame). Also the place to analyse or delete it.
class VideoPlayerPage extends StatefulWidget {
  final String videoId;
  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final ExerciseVideoStorage _storage = sl<ExerciseVideoStorage>();
  late final FormAnalysisRunner _runner = sl<FormAnalysisRunner>();

  ExerciseVideo? _video;
  VideoPlayerController? _controller;
  bool _loadFailed = false;
  bool _reportedPlay = false;
  double _speed = 1;

  static const _speeds = [0.25, 0.5, 1.0];

  @override
  void initState() {
    super.initState();
    _storage.addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    final video = await _storage.byId(widget.videoId);
    if (!mounted) return;
    if (video == null) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _video = video);
    try {
      final file = await _storage.videoFile(video);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onTick);
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _onTick() {
    if (!mounted) return;
    final playing = _controller?.value.isPlaying ?? false;
    if (playing && !_reportedPlay) {
      _reportedPlay = true;
      VideoAnalytics.played();
    }
    setState(() {});
  }

  Future<void> _refresh() async {
    final v = await _storage.byId(widget.videoId);
    if (!mounted) return;
    if (v == null) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _video = v);
    }
  }

  @override
  void dispose() {
    _storage.removeListener(_refresh);
    // Release the decoder so a long clip's memory is freed when the page closes.
    _controller
      ?..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  Future<void> _setSpeed(double speed) async {
    await _controller?.setPlaybackSpeed(speed);
    if (mounted) setState(() => _speed = speed);
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: video?.exerciseName ?? '',
              onBack: () => Navigator.of(context).maybePop(),
              onDelete: video == null
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      if (await confirmDeleteVideo(context, video)) navigator.maybePop();
                    },
            ),
            Expanded(
              child: Center(
                child: _loadFailed
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text("This video can't be played.",
                            style: GoogleFonts.inter(color: Colors.white70)),
                      )
                    : c == null
                        ? const CircularProgressIndicator(color: kVideoLime)
                        : GestureDetector(
                            onTap: () => c.value.isPlaying ? c.pause() : c.play(),
                            child: AspectRatio(
                              aspectRatio: c.value.aspectRatio,
                              child: VideoPlayer(c),
                            ),
                          ),
              ),
            ),
            if (c != null) _Controls(controller: c, speed: _speed, speeds: _speeds, onSpeed: _setSpeed),
            if (video != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: ListenableBuilder(
                  listenable: _runner,
                  builder: (context, _) => _Actions(
                    video: video,
                    runner: _runner,
                    onAnalyse: () => analyseFlow(context, video),
                    onOpen: () => openAnalysis(context, video.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The page's own header, drawn explicitly: white arrow on a visible rounded
/// tile, like the other screens, so it can't disappear into the black page.
class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onDelete;
  const _Header({required this.title, required this.onBack, this.onDelete});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String label, VoidCallback? onTap) => Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          tile(Icons.arrow_back_rounded, 'Back', onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 12),
            tile(Icons.delete_outline_rounded, 'Delete video', onDelete),
          ],
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final VideoPlayerController controller;
  final double speed;
  final List<double> speeds;
  final ValueChanged<double> onSpeed;
  const _Controls({
    required this.controller,
    required this.speed,
    required this.speeds,
    required this.onSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final v = controller.value;
    final total = v.duration.inMilliseconds.clamp(1, 1 << 30);
    final pos = v.position.inMilliseconds.clamp(0, total);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: v.isPlaying ? 'Pause' : 'Play',
                iconSize: 32,
                color: Colors.white,
                icon: Icon(v.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                onPressed: () => v.isPlaying ? controller.pause() : controller.play(),
              ),
              Expanded(
                child: Slider(
                  value: pos.toDouble(),
                  min: 0,
                  max: total.toDouble(),
                  activeColor: kVideoLime,
                  inactiveColor: Colors.white24,
                  onChanged: (x) => controller.seekTo(Duration(milliseconds: x.round())),
                ),
              ),
              Text(videoDuration(v.position),
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final s in speeds)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Semantics(
                    button: true,
                    selected: speed == s,
                    label: 'Playback speed ${s == 1 ? 'normal' : '$s times'}',
                    excludeSemantics: true,
                    // Plain pills, not ChoiceChip: the Material 3 chip painted its
                    // own light surface and the white label vanished on it.
                    child: GestureDetector(
                      onTap: () => onSpeed(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: speed == s ? kVideoLime : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s == 1 ? '1×' : '$s×',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: speed == s ? Colors.black : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final ExerciseVideo video;
  final FormAnalysisRunner runner;
  final VoidCallback onAnalyse;
  final VoidCallback onOpen;
  const _Actions({
    required this.video,
    required this.runner,
    required this.onAnalyse,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final job = runner.jobFor(video.id);
    if (job != null && job.isRunning) {
      return Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: kVideoLime),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Analysing your form… this can take up to a minute.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => runner.cancel(video.id),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
        ],
      );
    }
    if (video.isAnalysed) {
      return Row(
        children: [
          RatingChip(analysis: video.analysis!),
          const SizedBox(width: 12),
          Expanded(child: VideoPrimaryButton(label: 'View analysis', onTap: onOpen)),
        ],
      );
    }
    return VideoPrimaryButton(
      label: 'Analyse my form',
      icon: Icons.auto_awesome_rounded,
      onTap: onAnalyse,
    );
  }
}
