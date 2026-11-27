import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/domain/models/session_share.dart';
import 'package:fitness/domain/models/volume_format.dart';
import 'package:fitness/ui/core/constants/assets.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/muscle_map/views/body_figure.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The two shapes an image can be shared as. Rendered at three times these
/// sizes: 1080×1920 for stories, 1080×1350 for posts.
enum ShareFormat {
  story('Story', Size(360, 640)),
  post('Post', Size(360, 450));

  const ShareFormat(this.label, this.size);
  final String label;
  final Size size;
}

/// The logo, decoded at the size it is drawn: the file itself is 4096 pixels
/// wide, which is slow to load and would be missing from a quick capture.
const kShareLogo = ResizeImage(AssetImage(ImagePath.appLogo), width: 330);

/// `100 kg × 7`, `12 reps` or `45s`.
String shareSetText(ShareLift l, {required bool imperial}) {
  if (l.weightKg != null) {
    return '${formatSetWeight(l.weightKg!, imperial: imperial)} × ${l.reps ?? 0}';
  }
  if (l.durationSec != null) return '${l.durationSec}s';
  return '${l.reps ?? 0} reps';
}

/// The picture of one workout. Fixed size and fixed text scale, so it looks the
/// same on every phone.
class SessionShareGraphic extends StatelessWidget {
  final SessionShare share;
  final bool imperial;
  final ShareFormat format;

  /// The body drawing. Without it the image leaves the muscle map out.
  final BodyMap? map;

  const SessionShareGraphic({
    super.key,
    required this.share,
    required this.imperial,
    required this.format,
    this.map,
  });

  bool get _story => format == ShareFormat.story;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox.fromSize(
        size: format.size,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _Backdrop(),
              Padding(
                padding: EdgeInsets.fromLTRB(24, _story ? 28 : 20, 24, _story ? 22 : 16),
                child: _story ? _storyLayout() : _postLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _showMap => map != null && share.muscleLevels.isNotEmpty;

  Widget _storyLayout() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(share.date),
          const SizedBox(height: 22),
          _Title(share, size: 38),
          const SizedBox(height: 14),
          _Hero(share, imperial: imperial, size: 58),
          const SizedBox(height: 14),
          _Stats(share),
          const SizedBox(height: 12),
          Expanded(child: _showMap ? _Bodies(map!, share.muscleLevels) : const SizedBox.shrink()),
          const SizedBox(height: 12),
          _Lifts(share, imperial: imperial, count: 4),
          const SizedBox(height: 12),
          const _Footer(),
        ],
      );

  Widget _postLayout() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(share.date),
          const SizedBox(height: 12),
          _Title(share, size: 28),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _Hero(share, imperial: imperial, size: 46),
                  ),
                ),
                if (_showMap) SizedBox(width: 128, child: _Bodies(map!, share.muscleLevels)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _Stats(share),
          const SizedBox(height: 12),
          _Lifts(share, imperial: imperial, count: 3),
          const SizedBox(height: 10),
          const _Footer(),
        ],
      );
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E1218), kBodyBg, Color(0xFF07090D)],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1.1, -0.75),
              radius: 1.05,
              colors: [Color(0x3DCCFF00), Color(0x00CCFF00)],
            ),
          ),
          child: CustomPaint(painter: _Slashes()),
        ),
      );
}

/// Three thin diagonal strokes in the corner.
class _Slashes extends CustomPainter {
  const _Slashes();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      paint
        ..color = kBodyLime.withValues(alpha: 0.20 - i * 0.055)
        ..strokeWidth = 10 - i * 2.5;
      final x = size.width - 74 + i * 26.0;
      canvas.drawLine(Offset(x + 46, 70), Offset(x - 4, 150), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Slashes oldDelegate) => false;
}

class _Header extends StatelessWidget {
  final DateTime date;
  const _Header(this.date);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          // The logo file has wide margins: covering a short box trims the top
          // and bottom, and the nudge lines its left edge up with the title.
          Transform.translate(
            offset: const Offset(-9, 0),
            child: const SizedBox(
              width: 92,
              height: 22,
              child: Image(image: kShareLogo, fit: BoxFit.cover, filterQuality: FilterQuality.high),
            ),
          ),
          const Spacer(),
          Text(DateFormat('EEE · MMM d, y', 'en_US').format(date).toUpperCase(),
              style: bodyText(10, color: kBodySoft, weight: FontWeight.w700).copyWith(letterSpacing: 1)),
        ],
      );
}

class _Title extends StatelessWidget {
  final SessionShare share;
  final double size;
  const _Title(this.share, {required this.size});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: size * 1.15,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(share.title, maxLines: 1, style: bodyHeading(size).copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
          if (share.muscles.isNotEmpty)
            Text(share.muscles.join(' · ').toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bodyText(11, color: kBodyLime, weight: FontWeight.w800).copyWith(letterSpacing: 1.6)),
        ],
      );
}

/// The one big number: weight moved, or reps when nothing was weighted.
class _Hero extends StatelessWidget {
  final SessionShare share;
  final bool imperial;
  final double size;
  const _Hero(this.share, {required this.imperial, required this.size});

  @override
  Widget build(BuildContext context) {
    final weighted = share.volumeKg > 0;
    final text = weighted ? formatVolume(share.volumeKg, imperial: imperial) : '${share.reps}';
    final parts = text.split(' ');
    final unit = weighted ? parts.last : '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scaled down so a huge total still fits the picture.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(parts.first,
                    style: bodyHeading(size, color: kBodyLime).copyWith(fontWeight: FontWeight.w800, height: 1.05)),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(unit, style: bodyHeading(size * 0.38, color: kBodyLime)),
                ],
              ],
            ),
        ),
        Text(weighted ? 'TOTAL WEIGHT MOVED' : 'TOTAL REPS',
            style: bodyText(10, color: kBodyMuted, weight: FontWeight.w700).copyWith(letterSpacing: 1.8)),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  final SessionShare share;
  const _Stats(this.share);

  @override
  Widget build(BuildContext context) {
    final items = [
      if (share.durationMins > 0) ('${share.durationMins}', 'MIN'),
      ('${share.exercises}', share.exercises == 1 ? 'EXERCISE' : 'EXERCISES'),
      ('${share.sets}', share.sets == 1 ? 'SET' : 'SETS'),
      if (share.reps > 0 && share.volumeKg > 0) ('${share.reps}', 'REPS'),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Column(
                children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text(items[i].$1, style: bodyHeading(19))),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(items[i].$2,
                        style: bodyText(8.5, color: kBodyMuted, weight: FontWeight.w700).copyWith(letterSpacing: 0.9)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Front and back of the body, brighter where more of the session went.
class _Bodies extends StatelessWidget {
  final BodyMap map;
  final Map<String, int> levels;
  const _Bodies(this.map, this.levels);

  Color _fill(String slug) => switch (levels[slug] ?? 0) {
        >= 4 => kBodyLime,
        3 => const Color(0xFFA8D400),
        2 => const Color(0xFF7E9E0A),
        1 => const Color(0xFF566B14),
        _ => const Color(0xFF333A4D),
      };

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final view in [map.front, map.back])
            Expanded(
              child: BodyFigure(
                view: view,
                fillFor: _fill,
                silhouetteColor: const Color(0xFF1E2431),
                outlineColor: kBodyBg,
              ),
            ),
        ],
      );
}

class _Lifts extends StatelessWidget {
  final SessionShare share;
  final bool imperial;
  final int count;
  const _Lifts(this.share, {required this.imperial, required this.count});

  @override
  Widget build(BuildContext context) {
    if (share.lifts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('TOP SETS',
                style: bodyText(10, color: kBodyMuted, weight: FontWeight.w800).copyWith(letterSpacing: 1.8)),
            const Spacer(),
            if (share.bests > 0)
              Text('${share.bests} NEW ${share.bests == 1 ? 'BEST' : 'BESTS'}',
                  style: bodyText(10, color: kBodyAmber, weight: FontWeight.w800).copyWith(letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 7),
        for (final l in share.lifts.take(count))
          Container(
            height: 31,
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: l.isBest ? kBodyAmber.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: l.isBest ? kBodyAmber.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                if (l.isBest) ...[
                  const Icon(Icons.emoji_events_rounded, size: 14, color: kBodyAmber),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(l.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyText(11.5, weight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Text(shareSetText(l, imperial: imperial),
                    style: bodyText(12, color: l.isBest ? kBodyAmber : kBodyLime, weight: FontWeight.w800)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: kBodyLime, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text('Tracked with BeFit', style: bodyText(10.5, color: kBodySoft, weight: FontWeight.w600)),
        ],
      );
}
