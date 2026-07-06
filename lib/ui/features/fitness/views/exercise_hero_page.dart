import 'dart:math' as math;

import 'package:fitness/data/services/api/youtube_video_cache.dart';
import 'package:fitness/data/services/fitness/log_parser_service.dart';
import 'package:fitness/data/services/workout_log/workout_log_remote_service.dart';
import 'package:fitness/domain/use_cases/exercise/search_youtube_videos_usecase.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/fitness/views/yt_player.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kLime     = Color(0xFFCCFF00);
const _kCard     = Color(0xFF111318);
const _kBorder   = Color(0xFF1E2330);
const _kDimWhite = Color(0x80FFFFFF);
const _kAmber    = Color(0xFFFFAA00);

class ExerciseHeroPage extends StatefulWidget {
  final Exercise exercise;
  final int exerciseIndex;
  final VoidCallback onComplete;

  const ExerciseHeroPage({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onComplete,
  });

  @override
  State<ExerciseHeroPage> createState() => _ExerciseHeroPageState();
}

class _ExerciseHeroPageState extends State<ExerciseHeroPage> {
  bool _isViewing = false;
  dynamic _videoContent;
  bool _isLoadingVideos = false;
  String? _errorMessage;
  final YouTubeVideoCache _videoCache = YouTubeVideoCache();

  // Controllers live here so data survives dialog close (X button).
  late final List<TextEditingController> _weightCtls;
  late final List<TextEditingController> _repsCtls;
  bool _logSaved = false;

  bool get _hasUnsavedData =>
      _weightCtls.any((c) => c.text.trim().isNotEmpty) && !_logSaved;

  @override
  void initState() {
    super.initState();
    _weightCtls = List.generate(widget.exercise.sets, (_) => TextEditingController());
    _repsCtls = List.generate(
      widget.exercise.sets,
      (_) => TextEditingController(text: widget.exercise.reps),
    );
    _loadCachedVideos();
  }

  @override
  void dispose() {
    for (final c in _weightCtls) { c.dispose(); }
    for (final c in _repsCtls) { c.dispose(); }
    super.dispose();
  }

  Future<void> _openLogDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _WorkoutLogDialog(
        exerciseName: widget.exercise.name,
        sets: widget.exercise.sets,
        targetReps: widget.exercise.reps,
        weightCtls: _weightCtls,
        repsCtls: _repsCtls,
      ),
    );
    if (saved == true && mounted) {
      await _saveToDatabase();
    }
  }

  Future<void> _saveToDatabase() async {
    try {
      final remote = sl<WorkoutLogRemoteDataSource>();
      // Build a plain Exercise with the actual reps/weight captured in the log
      // dialog, embedded in the sets notes field for record-keeping.
      final setsNotes = List.generate(widget.exercise.sets, (i) {
        final weight = _weightCtls[i].text.trim();
        final reps   = _repsCtls[i].text.trim();
        return 'set ${i + 1}: ${reps.isNotEmpty ? reps : '?'} reps'
               '${weight.isNotEmpty ? ' @ ${weight}kg' : ''}';
      }).join(' | ');

      final logged = Exercise(
        name:  widget.exercise.name,
        sets:  widget.exercise.sets,
        reps:  widget.exercise.reps,
        notes: setsNotes.isNotEmpty ? setsNotes : widget.exercise.notes,
      );

      await remote.saveCompleteSession(
        sessionDate: DateTime.now(),
        exercises: [logged],
        durationMins: 0,
      );
      if (mounted) {
        setState(() => _logSaved = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save log — $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _confirmLeave() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0F14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Save before leaving?',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('You have unsaved exercise data.',
            style: GoogleFonts.inter(color: const Color(0x80FFFFFF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: Text('Discard', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            child: Text('Save', style: GoogleFonts.inter(color: const Color(0xFFCCFF00))),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _saveToDatabase();
      return true;
    }
    return result == 'discard';
  }

  void _loadCachedVideos() {
    final cached = _videoCache.getCachedVideos(widget.exercise.name);
    if (cached == null) return;
    final contents = cached['contents'];
    if (contents is List && contents.isNotEmpty) {
      setState(() {
        _videoContent = cached;
        _isViewing = true;
      });
    }
  }

  Future<void> _loadVideos() async {
    if (_videoCache.hasCachedVideos(widget.exercise.name)) {
      setState(() {
        _videoContent = _videoCache.getCachedVideos(widget.exercise.name);
        _isViewing = true;
        _isLoadingVideos = false;
      });
      return;
    }

    setState(() {
      _isLoadingVideos = true;
      _errorMessage = null;
    });

    try {
      final result = await sl<SearchYouTubeVideosUsecase>()(
        widget.exercise.name,
        maxResults: 10,
      );
      _videoCache.cacheVideos(widget.exercise.name, result);
      setState(() {
        _videoContent = result;
        _isViewing = true;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingVideos = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_hasUnsavedData) {
          final leave = await _confirmLeave();
          if (leave && context.mounted) Navigator.of(context).pop();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Color(0xFF111111),
              Color(0xFF1C1C1E),
              Color(0xFF2A2A2A),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _HeroHeader(exerciseIndex: widget.exerciseIndex),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _ExerciseTitle(name: widget.exercise.name),
                      const SizedBox(height: 20),
                      _StatsCard(
                        sets: widget.exercise.sets,
                        reps: widget.exercise.reps,
                        onTapLog: _openLogDialog,
                      ),
                      if (widget.exercise.notes != null) ...[
                        const SizedBox(height: 20),
                        _InstructionsCard(notes: widget.exercise.notes!),
                      ],
                      const SizedBox(height: 20),
                      const _SafetyTip(),
                      const SizedBox(height: 28),
                      _VideoSection(
                        isViewing: _isViewing,
                        isLoading: _isLoadingVideos,
                        errorMessage: _errorMessage,
                        videoContent: _videoContent,
                        onLoad: _loadVideos,
                        onVideoTap: (videoId) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => YouTubePlayer(videoId: videoId),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              _CompleteButton(onComplete: widget.onComplete),
            ],
          ),
        ),
      ),
    ), // Scaffold
    ); // PopScope
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final int exerciseIndex;
  const _HeroHeader({required this.exerciseIndex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _kLime.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Exercise ${exerciseIndex + 1}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kLime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Title ────────────────────────────────────────────────────────────────────

class _ExerciseTitle extends StatelessWidget {
  final String name;
  const _ExerciseTitle({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: GoogleFonts.poppins(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.15,
      ),
    );
  }
}

// ── Stats card ───────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final int sets;
  final String reps;
  final VoidCallback onTapLog;

  const _StatsCard({
    required this.sets,
    required this.reps,
    required this.onTapLog,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapLog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _StatColumn(value: '$sets', label: 'Sets')),
              VerticalDivider(
                color: Colors.white.withValues(alpha: 0.08),
                thickness: 1,
                indent: 8,
                endIndent: 8,
              ),
              Expanded(child: _StatColumn(value: reps, label: 'Reps')),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: _kLime.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kLime.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: _kLime,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _kDimWhite,
          ),
        ),
      ],
    );
  }
}

// ── Instructions ─────────────────────────────────────────────────────────────

class _InstructionsCard extends StatelessWidget {
  final String notes;
  const _InstructionsCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder, width: 1),
          ),
          child: Text(
            notes,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Safety tip ───────────────────────────────────────────────────────────────

class _SafetyTip extends StatelessWidget {
  const _SafetyTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141208),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _kAmber.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _kAmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.lightbulb_rounded,
                size: 14,
                color: _kAmber,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Follow instructions carefully to avoid injury and maximize effectiveness.',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Video section ─────────────────────────────────────────────────────────────

class _VideoSection extends StatelessWidget {
  final bool isViewing;
  final bool isLoading;
  final String? errorMessage;
  final dynamic videoContent;
  final VoidCallback onLoad;
  final void Function(String videoId) onVideoTap;

  const _VideoSection({
    required this.isViewing,
    required this.isLoading,
    required this.errorMessage,
    required this.videoContent,
    required this.onLoad,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.play_circle_outline_rounded,
              size: 18,
              color: _kLime,
            ),
            const SizedBox(width: 8),
            Text(
              'Video Tutorials',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (!isViewing)
          _VideoPlaceholder(onLoad: onLoad)
        else if (isLoading)
          const _VideoLoading()
        else if (errorMessage != null)
          _VideoError(message: errorMessage!, onRetry: onLoad)
        else if (videoContent != null && videoContent is Map)
          _VideoList(videoContent: videoContent, onTap: onVideoTap)
        else
          const _VideoEmpty(),
      ],
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final VoidCallback onLoad;
  const _VideoPlaceholder({required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLoad,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _kLime.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: _kLime,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Load Tutorials',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to fetch related YouTube videos',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _kDimWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoLoading extends StatelessWidget {
  const _VideoLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_kLime),
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _VideoError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _VideoError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.withValues(alpha: 0.8),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            'Failed to load videos',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 12, color: _kDimWhite),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder, width: 1),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kLime,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoEmpty extends StatelessWidget {
  const _VideoEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: Colors.white.withValues(alpha: 0.3),
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            'No videos found',
            style: GoogleFonts.inter(fontSize: 14, color: _kDimWhite),
          ),
        ],
      ),
    );
  }
}

class _VideoList extends StatelessWidget {
  final dynamic videoContent;
  final void Function(String videoId) onTap;
  const _VideoList({required this.videoContent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final contents = videoContent['contents'] as List<dynamic>?;
    if (contents == null || contents.isEmpty) return const _VideoEmpty();

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: contents.length,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(right: i < contents.length - 1 ? 12 : 0),
          child: _VideoCard(video: contents[i], onTap: onTap),
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final dynamic video;
  final void Function(String videoId) onTap;
  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String videoId = '';
    String thumbnail = '';
    String? title;

    try {
      if (video is Map && video.containsKey('video')) {
        final data = video['video'] as Map?;
        if (data != null) {
          videoId = data['videoId'] as String? ?? '';
          final thumbs = data['thumbnails'] as List?;
          if (thumbs != null && thumbs.isNotEmpty) {
            final t = (thumbs.length > 1 ? thumbs[1] : thumbs[0]) as Map?;
            thumbnail = t?['url'] as String? ?? '';
          }
          title = data['title'] as String?;
        }
      }
    } catch (_) {}

    return GestureDetector(
      onTap: videoId.isNotEmpty ? () => onTap(videoId) : null,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnail.isNotEmpty)
                Image.network(
                  thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _thumbFallback(),
                )
              else
                _thumbFallback(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              if (title != null && title.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        color: _kCard,
        child: const Center(
          child: Icon(
            Icons.video_library_outlined,
            color: Colors.white24,
            size: 40,
          ),
        ),
      );
}

// ── Complete button ───────────────────────────────────────────────────────────

class _CompleteButton extends StatelessWidget {
  final VoidCallback onComplete;
  const _CompleteButton({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: GestureDetector(
        onTap: onComplete,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            color: _kLime,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _kLime.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              Text(
                'Mark Complete',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.check_rounded,
                color: Colors.black,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Workout log dialog ────────────────────────────────────────────────────────

class _WorkoutLogDialog extends StatefulWidget {
  final String exerciseName;
  final int sets;
  final String targetReps;
  final List<TextEditingController> weightCtls;
  final List<TextEditingController> repsCtls;

  const _WorkoutLogDialog({
    required this.exerciseName,
    required this.sets,
    required this.targetReps,
    required this.weightCtls,
    required this.repsCtls,
  });

  @override
  State<_WorkoutLogDialog> createState() => _WorkoutLogDialogState();
}

class _WorkoutLogDialogState extends State<_WorkoutLogDialog> {
  List<TextEditingController> get _weightCtls => widget.weightCtls;
  List<TextEditingController> get _repsCtls => widget.repsCtls;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final _logParser = LogParserService();
  bool _sttAvailable = false;
  bool _isListening = false;
  bool _isParsing = false;
  bool _userStopped = false;
  double _soundLevel = 0.0;
  String _statusText = '';
  String _liveText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _sttAvailable = await _speech.initialize(
      onStatus: (status) {
        // The engine reports 'done'/'notListening' after each utterance segment.
        // If the user hasn't tapped stop, restart immediately to keep listening.
        if ((status == 'done' || status == 'notListening') && mounted) {
          if (_isListening && !_userStopped) {
            _restartListening();
          }
        }
      },
      onError: (e) {
        // Restart on transient errors (e.g. network, no-speech timeout)
        // unless the user explicitly stopped.
        if (mounted && _isListening && !_userStopped) {
          _restartListening();
        } else if (mounted) {
          setState(() { _isListening = false; _statusText = 'Error: ${e.errorMsg}'; });
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _restartListening() async {
    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted || _userStopped) return;
    await _startSession();
  }

  Future<void> _startSession() async {
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        // Accumulate words — keep building liveText with every partial result.
        setState(() => _liveText = result.recognizedWords);
      },
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _soundLevel = level.clamp(0, 10) / 10);
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 30), // long enough not to interrupt naturally
        localeId: 'en_US',
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (!_sttAvailable) {
      setState(() => _statusText = 'Speech recognition not available');
      return;
    }
    if (_isListening) {
      _userStopped = true;
      await _speech.stop();
      final captured = _liveText;
      setState(() { _isListening = false; _soundLevel = 0; });
      if (captured.trim().isNotEmpty) {
        await _parseWithAI(captured);
      }
      return;
    }
    _userStopped = false;
    setState(() { _isListening = true; _liveText = ''; _soundLevel = 0; _statusText = ''; });
    await _startSession();
  }

  Future<void> _parseWithAI(String transcript) async {
    if (!mounted) return;
    setState(() { _isParsing = true; _statusText = ''; });
    try {
      final sets = await _logParser.parseSpeech(
        transcript: transcript,
        numSets: widget.sets,
      );
      if (!mounted) return;
      for (var i = 0; i < sets.length && i < widget.sets; i++) {
        final s = sets[i];
        if (s.weightKg != null) {
          _weightCtls[i].text = s.weightKg! % 1 == 0
              ? s.weightKg!.toInt().toString()
              : s.weightKg!.toStringAsFixed(1);
        }
        if (s.reps != null) {
          _repsCtls[i].text = s.reps!.toString();
        }
      }
      setState(() { _isParsing = false; _liveText = ''; });
    } catch (_) {
      if (!mounted) return;
      // AI failed — keep the transcript visible so the user can enter manually
      setState(() { _isParsing = false; _statusText = 'Could not parse — please fill in manually'; });
    }
  }

  void _onSaveLog() {
    // Collect which set numbers have incomplete data.
    final emptySets = <int>[];
    for (var i = 0; i < widget.sets; i++) {
      final weightMissing = _weightCtls[i].text.trim().isEmpty;
      final repsMissing = _repsCtls[i].text.trim().isEmpty;
      if (weightMissing || repsMissing) emptySets.add(i + 1);
    }

    if (emptySets.isNotEmpty) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0D0F14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Incomplete sets',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: Text(
            'Please fill in weight and reps for set${emptySets.length > 1 ? 's' : ''} '
            '${emptySets.join(', ')} before saving.',
            style: GoogleFonts.inter(
              color: const Color(0x80FFFFFF),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Got it',
                style: GoogleFonts.inter(color: const Color(0xFFCCFF00)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // All sets complete — pop with true so the parent saves to DB.
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _userStopped = true;
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kLime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _kLime.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.edit_note_rounded, color: _kLime, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exerciseName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.sets} sets · ${widget.targetReps} reps target',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _kDimWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Voice-log mic ────────────────────────────────────────
                  GestureDetector(
                    onTap: _sttAvailable ? _toggleListening : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? _kLime
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isListening
                              ? _kLime
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: _isListening
                            ? Colors.black
                            : (_sttAvailable ? _kLime : Colors.white24),
                        size: 18,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Column labels ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const SizedBox(width: 44),
                  Expanded(
                    child: Text(
                      'Weight (kg)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kDimWhite,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reps done',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kDimWhite,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            ),
            const SizedBox(height: 8),
            // ── Set rows / waveform / parsing indicator ──────────────────────
            if (_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _WaveformView(level: _soundLevel, liveText: _liveText),
              )
            else if (_isParsing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 28, height: 28,
                      child: CircularProgressIndicator(
                        color: _kLime, strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AI is parsing your log…',
                      style: GoogleFonts.inter(fontSize: 13, color: _kDimWhite),
                    ),
                    if (_liveText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"$_liveText"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white38,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: List.generate(
                      widget.sets,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SetRow(
                          setNumber: i + 1,
                          weightCtl: _weightCtls[i],
                          repsCtl: _repsCtls[i],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_statusText.isNotEmpty && !_isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _statusText,
                  style: GoogleFonts.inter(fontSize: 12, color: _kDimWhite),
                ),
              ),
            // ── Save button ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSaveLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kLime,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save log',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Waveform animation ────────────────────────────────────────────────────────

class _WaveformView extends StatefulWidget {
  final double level;
  final String liveText;

  const _WaveformView({required this.level, required this.liveText});

  @override
  State<_WaveformView> createState() => _WaveformViewState();
}

class _WaveformViewState extends State<_WaveformView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(7, (i) {
                final phase = (i / 7) * 2 * math.pi;
                final base = (math.sin(_ctrl.value * 2 * math.pi + phase) + 1) / 2;
                final height = 12.0 + (base * 44 * (0.3 + widget.level * 0.7));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 5,
                    height: height,
                    decoration: BoxDecoration(
                      color: _kLime.withValues(alpha: 0.7 + base * 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.liveText.isNotEmpty
              ? Container(
                  key: const ValueKey('live'),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kLime.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kLime.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    widget.liveText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                )
              : Text(
                  key: const ValueKey('hint'),
                  'Say: "80 kilos 10 reps, 75 kilos 8 reps"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white30),
                ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Set rows ──────────────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  final int setNumber;
  final TextEditingController weightCtl;
  final TextEditingController repsCtl;

  const _SetRow({
    required this.setNumber,
    required this.weightCtl,
    required this.repsCtl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Set number bubble
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _kLime.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$setNumber',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kLime,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Weight field
          Expanded(child: _LogField(controller: weightCtl, hint: '0', suffix: 'kg')),
          const SizedBox(width: 12),
          // Reps field
          Expanded(child: _LogField(controller: repsCtl, hint: '0', suffix: 'reps')),
        ],
      ),
    );
  }
}

class _LogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;

  const _LogField({
    required this.controller,
    required this.hint,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.25),
        ),
        suffixText: suffix,
        suffixStyle: GoogleFonts.inter(
          fontSize: 11,
          color: _kDimWhite,
        ),
        filled: true,
        fillColor: _kCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _kBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kLime, width: 1.5),
        ),
      ),
    );
  }
}
