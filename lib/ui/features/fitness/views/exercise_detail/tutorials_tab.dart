import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:flutter/material.dart';

/// The "Tutorials" tab: YouTube videos for the movement, fetched when asked.
class TutorialsTab extends StatelessWidget {
  final bool isViewing;
  final bool isLoading;
  final String? errorMessage;
  final dynamic videoContent;
  final VoidCallback onLoad;
  final void Function(String videoId) onVideoTap;

  /// Paid-only: the tab shows a locked card in place of the videos.
  final bool locked;

  const TutorialsTab({
    super.key,
    required this.isViewing,
    required this.isLoading,
    required this.errorMessage,
    required this.videoContent,
    required this.onLoad,
    required this.onVideoTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    // Locked: no list, no thumbnails, nothing fetched. Showing the videos and
    // gating only the tap gave the feature away.
    if (locked) {
      return PremiumLockedCard(feature: PremiumFeature.videoTutorial, onUnlocked: onLoad);
    }
    // Loading and failure come before "not loaded yet", or the first load shows
    // neither.
    if (isLoading) {
      return const _Panel(
        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: kBodyLime)),
      );
    }
    if (errorMessage != null) {
      return _Panel(
        onTap: onLoad,
        child: const _Message(icon: Icons.error_outline_rounded, title: 'Failed to load videos', action: 'Retry'),
      );
    }
    if (!isViewing) {
      return _Panel(
        onTap: onLoad,
        child: const _Message(icon: Icons.play_circle_outline_rounded, title: 'Load Tutorials', action: 'Tap to fetch YouTube videos'),
      );
    }
    final contents = videoContent is Map ? videoContent['contents'] : null;
    if (contents is! List || contents.isEmpty) {
      return const _Panel(child: _Message(icon: Icons.video_library_outlined, title: 'No videos found'));
    }
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: contents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _Tile(video: contents[i], onTap: onVideoTap),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Panel({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kBodyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBodyBorder),
          ),
          child: child,
        ),
      );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? action;
  const _Message({required this.icon, required this.title, this.action});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: kBodyLime),
          const SizedBox(height: 8),
          Text(title, style: bodyText(13.5, weight: FontWeight.w600)),
          if (action != null) ...[
            const SizedBox(height: 3),
            Text(action!, style: bodyText(11.5, color: kBodyMuted)),
          ],
        ],
      );
}

class _Tile extends StatelessWidget {
  final dynamic video;
  final void Function(String videoId) onTap;
  const _Tile({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    var videoId = '';
    var thumbnail = '';
    String? title;
    try {
      final data = video is Map ? video['video'] as Map? : null;
      if (data != null) {
        videoId = data['videoId'] as String? ?? '';
        final thumbs = data['thumbnails'] as List?;
        if (thumbs != null && thumbs.isNotEmpty) {
          final t = (thumbs.length > 1 ? thumbs[1] : thumbs[0]) as Map?;
          thumbnail = t?['url'] as String? ?? '';
        }
        title = data['title'] as String?;
      }
    } catch (_) {}

    const fallback = ColoredBox(
      color: Color(0xFF1B2030),
      child: Center(child: Icon(Icons.video_library_outlined, color: Colors.white24, size: 28)),
    );

    return Semantics(
      button: true,
      label: title ?? 'Tutorial video',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: videoId.isNotEmpty ? () => onTap(videoId) : null,
        child: Container(
          width: 108,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBodyBorder),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnail.isNotEmpty)
                Image.network(thumbnail, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
              else
                fallback,
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x1A000000), Color(0xCC000000)],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: kBodyBg, size: 22),
                ),
              ),
              if (title != null && title.isNotEmpty)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 8,
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: bodyText(10.5, weight: FontWeight.w600, height: 1.25)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
