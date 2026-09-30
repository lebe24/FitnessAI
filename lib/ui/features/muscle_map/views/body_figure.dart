import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:flutter/material.dart';

/// One view of the body, drawn from [BodyView] outlines.
///
/// Muscles are filled with [muscleColor] and the [selected] one with
/// [selectedColor]. Parts that are not muscles take [silhouetteColor]. When
/// [onSelect] is set, a tap reports the muscle under the finger. Taps on the
/// silhouette or on empty space are ignored.
class BodyFigure extends StatelessWidget {
  final BodyView view;
  final String? selected;
  final ValueChanged<String>? onSelect;
  final Color muscleColor;
  final Color selectedColor;
  final Color silhouetteColor;
  final Color outlineColor;

  const BodyFigure({
    super.key,
    required this.view,
    this.selected,
    this.onSelect,
    this.muscleColor = const Color(0xFF2A3040),
    this.selectedColor = const Color(0xFFCCFF00),
    this.silhouetteColor = const Color(0xFF1A1E28),
    this.outlineColor = const Color(0xFF0A0C12),
  });

  @override
  Widget build(BuildContext context) {
    final figure = CustomPaint(
      painter: _BodyPainter(
        view: view,
        selected: selected,
        muscleColor: muscleColor,
        selectedColor: selectedColor,
        silhouetteColor: silhouetteColor,
        outlineColor: outlineColor,
      ),
      child: const SizedBox.expand(),
    );
    if (onSelect == null) return figure;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _handleTap(context, details.localPosition),
      child: figure,
    );
  }

  void _handleTap(BuildContext context, Offset local) {
    final box = context.size;
    if (box == null) return;
    final slug = view.muscleAt(BodyFit.of(view.size, box).toDrawing(local));
    if (slug != null) onSelect!(slug);
  }
}

class _BodyPainter extends CustomPainter {
  final BodyView view;
  final String? selected;
  final Color muscleColor;
  final Color selectedColor;
  final Color silhouetteColor;
  final Color outlineColor;

  const _BodyPainter({
    required this.view,
    required this.selected,
    required this.muscleColor,
    required this.selectedColor,
    required this.silhouetteColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fit = BodyFit.of(view.size, size);
    if (fit.scale == 0) return;

    canvas
      ..save()
      ..translate(fit.offset.dx, fit.offset.dy)
      ..scale(fit.scale);

    final fill = Paint()..isAntiAlias = true;
    // Divided by the scale so the seams between muscles stay about a pixel
    // wide whether the figure is a thumbnail or fills the screen.
    final seam = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / fit.scale
      ..color = outlineColor;

    fill.color = silhouetteColor;
    for (final slug in kInertBodyParts) {
      for (final path in view.parts[slug] ?? const <Path>[]) {
        canvas.drawPath(path, fill);
      }
    }

    for (final muscle in Muscle.all) {
      fill.color = muscle.slug == selected ? selectedColor : muscleColor;
      for (final path in view.parts[muscle.slug] ?? const <Path>[]) {
        canvas
          ..drawPath(path, fill)
          ..drawPath(path, seam);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.view != view ||
      old.selected != selected ||
      old.muscleColor != muscleColor ||
      old.selectedColor != selectedColor ||
      old.silhouetteColor != silhouetteColor ||
      old.outlineColor != outlineColor;
}
