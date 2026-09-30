import 'package:fitness/data/models/youtube/video_summary.dart';
import 'package:fitness/data/services/api/youtube_video_cache.dart';
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/fitness/muscle_advisor_service.dart';
import 'package:fitness/domain/models/friendly_error.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/domain/use_cases/exercise/search_youtube_videos_usecase.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/fitness/views/yt_player.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBg = Color(0xFF0A0C12);
const _kCard = Color(0xFF111318);
const _kCard2 = Color(0xFF161B26);
const _kBorder = Color(0xFF1E2330);
const _kLime = Color(0xFFCCFF00);
const _kDim = Color(0x80FFFFFF);

enum _AdvisorState { idle, loading, done, error }

/// One muscle, in the context of what the user has actually trained.
///
/// Reached by tapping the body map. Three things in order: how much of their
/// training this muscle gets, which movements produced it, and — on request —
/// what to do about it.
class MuscleDetailPage extends StatefulWidget {
  final Muscle muscle;
  final MuscleCoverage coverage;
  final int sessionCount;

  const MuscleDetailPage({
    super.key,
    required this.muscle,
    required this.coverage,
    required this.sessionCount,
  });

  @override
  State<MuscleDetailPage> createState() => _MuscleDetailPageState();
}

class _MuscleDetailPageState extends State<MuscleDetailPage> {
  final _videoCache = YouTubeVideoCache();
  final _advisor = MuscleAdvisorService();

  _AdvisorState _advisorState = _AdvisorState.idle;
  String _advice = '';

  bool _videosRequested = false;
  bool _videosLoading = false;
  String? _videoError;
  List<VideoSummary> _videos = const [];

  @override
  void initState() {
    super.initState();
    final cached = _videoCache.getCachedVideos(_cacheKey);
    if (cached != null) {
      _videosRequested = true;
      _videos = VideoSummary.listFrom(cached);
    }
  }

  String get _cacheKey => 'muscle:${widget.muscle.slug}';

  Future<void> _askAdvisor() async {
    setState(() => _advisorState = _AdvisorState.loading);
    final c = widget.coverage;
    final slug = widget.muscle.slug;
    final ranked = c.ranked;

    try {
      final message = await _advisor.advise(
        muscle: widget.muscle.name,
        muscleSets: c.load[slug] ?? 0,
        totalSets: c.totalLoad,
        sessions: widget.sessionCount,
        exercises: c.exercisesFor(slug).map((e) => e.key).toList(),
        mostTrained: ranked
            .take(3)
            .map((s) => Muscle.bySlug(s)?.name ?? s)
            .toList(),
        // The muscles with the least work are the ones advice is usually
        // about, so they go in as well as the headline ones.
        leastTrained: ranked.reversed
            .take(3)
            .map((s) => Muscle.bySlug(s)?.name ?? s)
            .toList(),
      );
      if (!mounted) return;
      setState(() {
        _advice = message;
        _advisorState = _AdvisorState.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _advice = FriendlyError.from(e).message;
        _advisorState = _AdvisorState.error;
      });
    }
  }

  Future<void> _loadVideos() async {
    setState(() {
      _videosRequested = true;
      _videosLoading = true;
      _videoError = null;
    });
    try {
      final result = await sl<SearchYouTubeVideosUsecase>()(
        widget.muscle.searchTerm,
        maxResults: 10,
      );
      _videoCache.cacheVideos(_cacheKey, result);
      if (!mounted) return;
      setState(() {
        _videos = VideoSummary.listFrom(result);
        _videosLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _videoError = FriendlyError.from(e).message;
        _videosLoading = false;
      });
    }
  }

  void _playVideo(String videoId) {
    requirePremium(
      context,
      PremiumFeature.videoTutorial,
      () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => YouTubePlayer(videoId: videoId)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coverage;
    final slug = widget.muscle.slug;
    final exercises = c.exercisesFor(slug);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: widget.muscle.name,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShareCard(
                      share: c.sharePercent(slug),
                      sets: c.load[slug] ?? 0,
                      sessions: widget.sessionCount,
                      rank: c.ranked.indexOf(slug),
                      trained: c.ranked.length,
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(
                      icon: Icons.fitness_center_rounded,
                      label: 'How you trained it',
                    ),
                    const SizedBox(height: 12),
                    if (exercises.isEmpty)
                      const _NothingLogged()
                    else
                      _ExerciseList(exercises: exercises),
                    const SizedBox(height: 28),
                    _SectionTitle(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Coach',
                    ),
                    const SizedBox(height: 12),
                    _Advisor(
                      state: _advisorState,
                      message: _advice,
                      muscle: widget.muscle.name,
                      onAsk: _askAdvisor,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        _SectionTitle(
                          icon: Icons.play_circle_outline_rounded,
                          label: 'Tutorials',
                        ),
                        const SizedBox(width: 8),
                        PremiumBadge(
                          visible: !sl<AccessPolicy>()
                              .canUse(PremiumFeature.videoTutorial),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Videos(
                      muscle: widget.muscle,
                      requested: _videosRequested,
                      loading: _videosLoading,
                      error: _videoError,
                      videos: _videos,
                      onLoad: _loadVideos,
                      onPlay: _playVideo,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chrome ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: _kLime),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ── Share of training ─────────────────────────────────────────────────────────

class _ShareCard extends StatelessWidget {
  final double share;
  final double sets;
  final int sessions;
  final int rank;
  final int trained;

  const _ShareCard({
    required this.share,
    required this.sets,
    required this.sessions,
    required this.rank,
    required this.trained,
  });

  /// "your most trained" reads better than "#1 of 15", and the exact position
  /// stops being meaningful past the first few.
  String get _standing {
    if (rank < 0) return 'Not trained yet';
    if (rank == 0) return 'Your most trained muscle';
    if (rank == 1) return 'Your 2nd most trained';
    if (rank == 2) return 'Your 3rd most trained';
    return '${rank + 1}th of $trained muscles trained';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${share.round()}%',
                style: GoogleFonts.poppins(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: _kLime,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'of your training',
                  style: GoogleFonts.inter(fontSize: 13, color: _kDim),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _standing,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (share / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: _kCard2,
              valueColor: const AlwaysStoppedAnimation<Color>(_kLime),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${sets.round()} sets across $sessions ${sessions == 1 ? 'session' : 'sessions'}',
            style: GoogleFonts.inter(fontSize: 12, color: _kDim),
          ),
        ],
      ),
    );
  }
}

// ── What trained it ───────────────────────────────────────────────────────────

class _ExerciseList extends StatelessWidget {
  final List<MapEntry<String, double>> exercises;
  const _ExerciseList({required this.exercises});

  @override
  Widget build(BuildContext context) {
    final max = exercises.first.value;
    return Column(
      children: [
        for (final e in exercises)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 54,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: e.value / max,
                      minHeight: 5,
                      backgroundColor: _kCard2,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_kLime),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${e.value.round()} sets',
                  style: GoogleFonts.inter(fontSize: 11.5, color: _kDim),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NothingLogged extends StatelessWidget {
  const _NothingLogged();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.remove_circle_outline_rounded,
              size: 30, color: Colors.white.withValues(alpha: 0.28)),
          const SizedBox(height: 10),
          Text(
            'No logged sets on this muscle yet',
            style: GoogleFonts.inter(fontSize: 13, color: _kDim),
          ),
          const SizedBox(height: 4),
          Text(
            'Which is worth knowing — ask the coach what to do about it',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11.5, color: _kDim),
          ),
        ],
      ),
    );
  }
}

// ── Advisor ───────────────────────────────────────────────────────────────────

/// The advisor, behind a bubble the user has to press.
///
/// Not fetched on open: it costs a model call per muscle, and someone browsing
/// the map would spend one on every tap without reading any of them.
class _Advisor extends StatelessWidget {
  final _AdvisorState state;
  final String message;
  final String muscle;
  final VoidCallback onAsk;

  const _Advisor({
    required this.state,
    required this.message,
    required this.muscle,
    required this.onAsk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdvisorBubble(
          label: switch (state) {
            _AdvisorState.loading => 'Asking your coach…',
            _AdvisorState.done => 'Ask again',
            _AdvisorState.error => 'Try again',
            _AdvisorState.idle => 'Ask about my ${muscle.toLowerCase()}',
          },
          busy: state == _AdvisorState.loading,
          onTap: state == _AdvisorState.loading ? null : onAsk,
        ),
        if (state == _AdvisorState.done || state == _AdvisorState.error) ...[
          const SizedBox(height: 12),
          _AdviceCard(message: message, isError: state == _AdvisorState.error),
        ],
      ],
    );
  }
}

/// The pill from the workout page's plus menu, reused so the two AI entry
/// points look like the same feature.
class _AdvisorBubble extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  const _AdvisorBubble({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kLime),
                    )
                  : const Icon(Icons.auto_awesome_rounded,
                      color: _kLime, size: 16),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final String message;
  final bool isError;
  const _AdviceCard({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final accent = isError ? Colors.red : _kLime;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.withValues(alpha: 0.06)
            : _kLime.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          height: 1.6,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

// ── Videos ────────────────────────────────────────────────────────────────────

class _Videos extends StatelessWidget {
  final Muscle muscle;
  final bool requested;
  final bool loading;
  final String? error;
  final List<VideoSummary> videos;
  final VoidCallback onLoad;
  final ValueChanged<String> onPlay;

  const _Videos({
    required this.muscle,
    required this.requested,
    required this.loading,
    required this.error,
    required this.videos,
    required this.onLoad,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    if (!requested) {
      return _Panel(
        icon: Icons.play_arrow_rounded,
        title: 'Find ${muscle.name.toLowerCase()} tutorials',
        subtitle: 'Tap to search YouTube',
        onTap: onLoad,
        accent: true,
      );
    }
    if (loading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2.5, color: _kLime),
        ),
      );
    }
    if (error != null) {
      return _Panel(
        icon: Icons.error_outline_rounded,
        title: "Couldn't load videos",
        subtitle: error!,
        onTap: onLoad,
      );
    }
    if (videos.isEmpty) {
      return const _Panel(
        icon: Icons.video_library_outlined,
        title: 'No videos found',
        subtitle: 'Try another muscle.',
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) =>
            _VideoCard(video: videos[i], onTap: () => onPlay(videos[i].id)),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final VideoSummary video;
  final VoidCallback onTap;
  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (video.thumbnailUrl.isNotEmpty)
              Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ThumbFallback(),
              )
            else
              const _ThumbFallback(),
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
                      color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
            if (video.title.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) => Container(
        color: _kCard2,
        child: Icon(Icons.fitness_center_rounded,
            color: Colors.white.withValues(alpha: 0.2), size: 36),
      );
}

class _Panel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool accent;

  const _Panel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = accent ? _kLime : Colors.white.withValues(alpha: 0.4);
    final panel = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border:
                  Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 12, color: _kDim),
          ),
        ],
      ),
    );
    return onTap == null ? panel : GestureDetector(onTap: onTap, child: panel);
  }
}
