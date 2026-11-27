import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/video/views/video_widgets.dart';
import 'package:flutter/material.dart';

const _kBadge = Color(0xFF222A12);

/// The height every card has, so a grid of them lines up.
const double kVideoCatalogCardHeight = 220;

/// One saved video in the Workout videos catalog: its picture, the exercise,
/// when it was filmed and how long it is, and a badge once its form is checked.
class VideoCatalogCard extends StatefulWidget {
  final ExerciseVideo video;
  final ExerciseVideoStorage storage;
  final VoidCallback onTap;

  const VideoCatalogCard({
    super.key,
    required this.video,
    required this.storage,
    required this.onTap,
  });

  @override
  State<VideoCatalogCard> createState() => _VideoCatalogCardState();
}

class _VideoCatalogCardState extends State<VideoCatalogCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    final length = videoDuration(v.duration);
    final when = shortDate(v.recordedAt);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${v.exerciseName}, $when, $length${v.isAnalysed ? ', form checked' : ''}',
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
            height: kVideoCatalogCardHeight,
            decoration: BoxDecoration(
              color: kBodyCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kBodyBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 148,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoThumbnail(video: v, storage: widget.storage),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x1A000000), Color(0x80000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(length, style: bodyText(10.5, weight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.exerciseName,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyHeading(13)),
                      const SizedBox(height: 3),
                      Text('$when · $length',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyText(11, color: kBodyMuted, weight: FontWeight.w400)),
                      if (v.isAnalysed) ...[
                        const SizedBox(height: 7),
                        // In a Row so the badge hugs its text instead of
                        // stretching across the card.
                        // Flexible and scaled down so it still fits a narrow
                        // card or a large text size.
                        Row(children: [
                          Flexible(
                            child: Container(
                              height: 18,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: _kBadge, borderRadius: BorderRadius.circular(9)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('FORM CHECKED',
                                    style: bodyText(8, color: kBodyLime, weight: FontWeight.w700)
                                        .copyWith(letterSpacing: 0.5)),
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
