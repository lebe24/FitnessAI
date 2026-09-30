import 'package:fitness/data/models/youtube/video_summary.dart';
import 'package:fitness/data/services/api/youtube_video_cache.dart';
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/domain/models/friendly_error.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/domain/use_cases/exercise/search_youtube_videos_usecase.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/fitness/views/yt_player.dart';
import 'package:fitness/ui/features/muscle_map/views/body_figure.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kDim    = Color(0x80FFFFFF);

/// Pick a muscle on the body, then find YouTube tutorials that train it.
///
/// The body geometry and the muscle list are ported from Iron Index. Iron
/// Index also shades each muscle by how many exercises in a list train it;
/// that part is not here, because BeFit's plan exercises carry a name, sets
/// and reps but no muscle data to shade from.
class MuscleMapPage extends StatefulWidget {
  const MuscleMapPage({super.key});

  @override
  State<MuscleMapPage> createState() => _MuscleMapPageState();
}

class _MuscleMapPageState extends State<MuscleMapPage> {
  final _videoCache = YouTubeVideoCache();

  BodyMap? _map;
  bool _mapFailed = false;
  String? _selected;

  bool _videosRequested = false;
  bool _videosLoading = false;
  String? _videoError;
  List<VideoSummary> _videos = const [];

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  Future<void> _loadMap() async {
    setState(() => _mapFailed = false);
    try {
      final map = await BodyMapSource.load();
      if (mounted) setState(() => _map = map);
    } catch (_) {
      if (mounted) setState(() => _mapFailed = true);
    }
  }

  /// Shares YouTubeVideoCache with the exercise page, so the prefix keeps a
  /// muscle called "Chest" from colliding with an exercise called "Chest".
  String _cacheKey(Muscle m) => 'muscle:${m.slug}';

  void _select(String slug) {
    final muscle = Muscle.bySlug(slug);
    if (muscle == null) return;
    final cached = _videoCache.getCachedVideos(_cacheKey(muscle));
    setState(() {
      _selected = slug;
      _videoError = null;
      _videosLoading = false;
      // Revisiting a muscle shows its videos straight away. A muscle not
      // searched yet waits for a tap: each search spends API quota, and
      // exploring the map should not burn it on every muscle touched.
      _videosRequested = cached != null;
      _videos = cached == null ? const [] : VideoSummary.listFrom(cached);
    });
  }

  Future<void> _loadVideos() async {
    final muscle = Muscle.bySlug(_selected);
    if (muscle == null) return;
    setState(() {
      _videosRequested = true;
      _videosLoading = true;
      _videoError = null;
    });
    try {
      final result = await sl<SearchYouTubeVideosUsecase>()(
        muscle.searchTerm,
        maxResults: 10,
      );
      _videoCache.cacheVideos(_cacheKey(muscle), result);
      // The user may have picked another muscle while this was in flight.
      if (!mounted || _selected != muscle.slug) return;
      setState(() {
        _videos = VideoSummary.listFrom(result);
        _videosLoading = false;
      });
    } catch (e) {
      if (!mounted || _selected != muscle.slug) return;
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
    final muscle = Muscle.bySlug(_selected);
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title(),
                    const SizedBox(height: 20),
                    _FiguresCard(
                      map: _map,
                      failed: _mapFailed,
                      selected: _selected,
                      onSelect: _select,
                      onRetry: _loadMap,
                    ),
                    const SizedBox(height: 16),
                    _MuscleChips(selected: _selected, onSelect: _select),
                    const SizedBox(height: 28),
                    if (muscle == null)
                      const _PickPrompt()
                    else
                      _MuscleVideos(
                        muscle: muscle,
                        requested: _videosRequested,
                        loading: _videosLoading,
                        error: _videoError,
                        videos: _videos,
                        // Listing is free; playing is not, as on the
                        // exercise page.
                        locked: !sl<AccessPolicy>()
                            .canUse(PremiumFeature.videoTutorial),
                        onLoad: _loadVideos,
                        onPlay: _playVideo,
                      ),
                    const SizedBox(height: 32),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
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
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
            children: const [
              TextSpan(text: 'Muscle '),
              TextSpan(
                text: 'Map',
                style: TextStyle(backgroundColor: _kLime, color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a muscle on the body, or pick one below, to find tutorials '
          'that train it.',
          style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: _kDim),
        ),
      ],
    );
  }
}

// ── Body figures ──────────────────────────────────────────────────────────────

class _FiguresCard extends StatelessWidget {
  final BodyMap? map;
  final bool failed;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onRetry;

  const _FiguresCard({
    required this.map,
    required this.failed,
    required this.selected,
    required this.onSelect,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final map = this.map;
    final Widget body;
    if (failed) {
      body = _MapError(onRetry: onRetry);
    } else if (map == null) {
      body = const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_kLime),
          strokeWidth: 2.5,
        ),
      );
    } else {
      body = Row(
        children: [
          Expanded(
            child: _LabelledFigure(
              label: 'Front',
              view: map.front,
              selected: selected,
              onSelect: onSelect,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _LabelledFigure(
              label: 'Back',
              view: map.back,
              selected: selected,
              onSelect: onSelect,
            ),
          ),
        ],
      );
    }

    return Container(
      height: 380,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: body,
    );
  }
}

class _LabelledFigure extends StatelessWidget {
  final String label;
  final BodyView view;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _LabelledFigure({
    required this.label,
    required this.view,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Semantics(
            label: '$label of body. Tap a muscle to select it.',
            child: BodyFigure(
              view: view,
              selected: selected,
              onSelect: onSelect,
              outlineColor: _kCard,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: _kDim,
          ),
        ),
      ],
    );
  }
}

class _MapError extends StatelessWidget {
  final VoidCallback onRetry;
  const _MapError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "The body map couldn't load",
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'You can still pick a muscle from the list below.',
            style: GoogleFonts.inter(fontSize: 12, color: _kDim),
          ),
          const SizedBox(height: 12),
          _SmallButton(label: 'Retry', onTap: onRetry),
        ],
      ),
    );
  }
}

// ── Muscle list ───────────────────────────────────────────────────────────────

/// Every muscle as a chip. Small regions like the shins are hard to hit on a
/// phone-sized figure, and this also works for screen readers and when the
/// drawing fails to load.
class _MuscleChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _MuscleChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in Muscle.all)
          _MuscleChip(
            muscle: m,
            selected: m.slug == selected,
            onTap: () => onSelect(m.slug),
          ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final Muscle muscle;
  final bool selected;
  final VoidCallback onTap;
  const _MuscleChip({
    required this.muscle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _kLime : _kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? _kLime : _kBorder),
          ),
          child: Text(
            muscle.name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.black : Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Videos ────────────────────────────────────────────────────────────────────

class _PickPrompt extends StatelessWidget {
  const _PickPrompt();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      icon: Icons.touch_app_outlined,
      title: 'Pick a muscle',
      subtitle: 'Its video tutorials will show up here.',
    );
  }
}

class _MuscleVideos extends StatelessWidget {
  final Muscle muscle;
  final bool requested;
  final bool loading;
  final String? error;
  final List<VideoSummary> videos;
  final bool locked;
  final VoidCallback onLoad;
  final ValueChanged<String> onPlay;

  const _MuscleVideos({
    required this.muscle,
    required this.requested,
    required this.loading,
    required this.error,
    required this.videos,
    required this.locked,
    required this.onLoad,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (!requested) {
      body = _Panel(
        icon: Icons.play_arrow_rounded,
        title: 'Find ${muscle.name.toLowerCase()} tutorials',
        subtitle: 'Tap to search YouTube',
        onTap: onLoad,
        accent: true,
      );
    } else if (loading) {
      body = const _VideosLoading();
    } else if (error != null) {
      body = _Panel(
        icon: Icons.error_outline_rounded,
        title: "Couldn't load videos",
        subtitle: error!,
        action: _SmallButton(label: 'Retry', onTap: onLoad),
      );
    } else if (videos.isEmpty) {
      body = const _Panel(
        icon: Icons.video_library_outlined,
        title: 'No videos found',
        subtitle: 'Try another muscle.',
      );
    } else {
      body = _VideoRow(videos: videos, onPlay: onPlay);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.play_circle_outline_rounded,
                size: 18, color: _kLime),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${muscle.name} tutorials',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PremiumBadge(visible: locked),
          ],
        ),
        const SizedBox(height: 14),
        body,
      ],
    );
  }
}

class _VideosLoading extends StatelessWidget {
  const _VideosLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
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

class _VideoRow extends StatelessWidget {
  final List<VideoSummary> videos;
  final ValueChanged<String> onPlay;
  const _VideoRow({required this.videos, required this.onPlay});

  @override
  Widget build(BuildContext context) {
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
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1E28),
      child: Icon(Icons.fitness_center_rounded,
          color: Colors.white.withValues(alpha: 0.2), size: 36),
    );
  }
}

// ── Shared pieces ─────────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? action;
  final bool accent;

  const _Panel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.action,
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
              border: Border.all(
                  color: iconColor.withValues(alpha: 0.3), width: 1.5),
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
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
    if (onTap == null) return panel;
    return GestureDetector(onTap: onTap, child: panel);
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmallButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: _kLime),
        ),
      ),
    );
  }
}
