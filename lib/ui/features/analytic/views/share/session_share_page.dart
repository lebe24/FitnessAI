import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/history_analytics.dart';
import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/data/services/share/image_sharer.dart';
import 'package:fitness/domain/models/session_share.dart';
import 'package:fitness/ui/core/widgets/centered_title_bar.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/analytic/views/share/session_share_graphic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

/// [boundary] as a PNG, [pixelRatio] times its size on screen.
Future<Uint8List> capturePng(RenderRepaintBoundary boundary, {required double pixelRatio}) async {
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Shows the picture of a workout as it will be sent, and sends it.
class SessionSharePage extends StatefulWidget {
  final SessionShare share;
  final bool imperial;

  /// The shape shown first.
  final ShareFormat initialFormat;

  /// Replaced in tests; by default the phone's share menu.
  final ImageSharer sharer;

  /// Replaced in tests; by default the app's body drawing.
  final Future<BodyMap> Function()? loadMap;

  /// Turns the picture on screen into PNG bytes. Replaced in tests; by default
  /// it waits for fonts and images and then captures.
  final Future<Uint8List> Function(RenderRepaintBoundary picture)? capture;

  const SessionSharePage({
    super.key,
    required this.share,
    required this.imperial,
    this.initialFormat = ShareFormat.story,
    this.sharer = const SystemImageSharer(),
    this.loadMap,
    this.capture,
  });

  /// Rendered at this multiple of the layout size: 1080 pixels wide.
  static const pixelRatio = 3.0;

  @override
  State<SessionSharePage> createState() => _SessionSharePageState();
}

class _SessionSharePageState extends State<SessionSharePage> {
  final _picture = GlobalKey();
  late ShareFormat _format = widget.initialFormat;
  BodyMap? _map;
  bool _mapSettled = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    Analytics.screen('share_workout');
    HistoryAnalytics.shareOpened(bests: widget.share.bests);
    _loadMap();
  }

  Future<void> _loadMap() async {
    try {
      final map = await (widget.loadMap ?? BodyMapSource.load)();
      if (mounted) setState(() => _map = map);
    } catch (_) {
      // The picture is still worth sharing without the drawing.
    }
    if (mounted) setState(() => _mapSettled = true);
  }

  /// The picture as PNG bytes, exactly as shown.
  Future<Uint8List> _render() {
    final picture = _picture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return (widget.capture ?? _whenReady)(picture);
  }

  /// Everything the picture draws must have arrived before it is captured.
  Future<Uint8List> _whenReady(RenderRepaintBoundary picture) async {
    try {
      await GoogleFonts.pendingFonts();
    } catch (_) {}
    if (mounted) await precacheImage(kShareLogo, context, onError: (_, __) {});
    await WidgetsBinding.instance.endOfFrame;
    return capturePng(picture, pixelRatio: SessionSharePage.pixelRatio);
  }

  Future<void> _share(BuildContext button) async {
    if (_sharing) return;
    // Where the share menu points from, which iPad needs. Read before waiting.
    final box = button.findRenderObject() as RenderBox?;
    final origin = box == null || !box.hasSize ? null : box.localToGlobal(Offset.zero) & box.size;
    final format = _format;
    setState(() => _sharing = true);
    try {
      final png = await _render();
      final d = widget.share.date;
      String two(int n) => n.toString().padLeft(2, '0');
      final outcome = await widget.sharer.share(
        png,
        fileName: 'befit-workout-${d.year}-${two(d.month)}-${two(d.day)}-${format.name}.png',
        origin: origin,
      );
      HistoryAnalytics.shareFinished(format: format.name, outcome: outcome.name);
    } catch (e) {
      debugPrint('Sharing failed: $e');
      HistoryAnalytics.shareFailed(format: format.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not share the picture. Please try again.', style: bodyText(13)),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBodyBg,
      body: SafeArea(
        child: Column(
          children: [
            const CenteredTitleBar(title: 'Share workout'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final f in ShareFormat.values) ...[
                  if (f != ShareFormat.values.first) const SizedBox(width: 8),
                  _FormatChip(f.label, selected: _format == f, onTap: () => setState(() => _format = f)),
                ],
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    // The rounded corners and shadow are only on screen; the
                    // boundary inside captures the plain rectangle.
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: kBodyBorder),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: RepaintBoundary(
                          key: _picture,
                          child: SessionShareGraphic(
                            share: widget.share,
                            imperial: widget.imperial,
                            format: _format,
                            map: _map,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Builder(
                builder: (button) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: BodyButton(
                    label: 'Share',
                    icon: Icons.ios_share_rounded,
                    busy: _sharing,
                    onPressed: _mapSettled && !_sharing ? () => _share(button) : null,
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

class _FormatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FormatChip(this.label, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: selected ? kBodyLime : kBodyChip,
              borderRadius: BorderRadius.circular(17),
              border: selected ? null : Border.all(color: kBodyBorder),
            ),
            child: Center(
              widthFactor: 1,
              child: Text(label, style: bodyText(13, color: selected ? kBodyBg : kBodySoft)),
            ),
          ),
        ),
      );
}
