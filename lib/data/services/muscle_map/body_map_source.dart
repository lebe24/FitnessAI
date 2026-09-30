import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:fitness/domain/models/muscle.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';

/// One side of the body: its outlines, already moved so the drawing starts at
/// the origin.
class BodyView {
  /// Width and height of the drawing, in its own units.
  final Size size;

  /// Outlines per body part, keyed by the slugs in [Muscle.all] and
  /// [kInertBodyParts]. A part is usually several paths, left and right.
  final Map<String, List<Path>> parts;

  const BodyView(this.size, this.parts);

  /// The muscle under [point], given in drawing units, or null.
  String? muscleAt(Offset point) {
    for (final m in Muscle.all) {
      for (final path in parts[m.slug] ?? const <Path>[]) {
        if (path.contains(point)) return m.slug;
      }
    }
    return null;
  }
}

class BodyMap {
  final BodyView front;
  final BodyView back;
  const BodyMap(this.front, this.back);
}

/// How a drawing sits inside the box it is painted into: scaled to fit whole
/// and centred, like BoxFit.contain.
///
/// The painter and hit-testing both go through this, so a tap always lands on
/// the muscle that was actually drawn under the finger.
class BodyFit {
  final double scale;
  final Offset offset;
  const BodyFit(this.scale, this.offset);

  factory BodyFit.of(Size drawing, Size box) {
    if (drawing.isEmpty || box.isEmpty) return const BodyFit(0, Offset.zero);
    final scale =
        math.min(box.width / drawing.width, box.height / drawing.height);
    return BodyFit(
      scale,
      Offset(
        (box.width - drawing.width * scale) / 2,
        (box.height - drawing.height * scale) / 2,
      ),
    );
  }

  /// A point in the painted box, converted to drawing units.
  Offset toDrawing(Offset local) =>
      scale == 0 ? Offset.infinite : (local - offset) / scale;
}

/// The body outlines, read from assets once and kept.
///
/// The geometry is MuscleMap by Melih Colpan (MIT), as converted for Iron
/// Index. Only the male front and back views ship: 42 KB, against 94 KB for
/// all four. Nothing in the app chooses a figure yet, and adding the female
/// views later means re-exporting the asset, not changing this code.
class BodyMapSource {
  static const asset = 'assets/data/body_map.json';
  static BodyMap? _cached;

  static Future<BodyMap> load([AssetBundle? bundle]) async {
    final cached = _cached;
    if (cached != null) return cached;
    final source = await (bundle ?? rootBundle).loadString(asset);
    return _cached = parse(source);
  }

  static BodyMap parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return BodyMap(_view(json['front']), _view(json['back']));
  }

  static BodyView _view(dynamic raw) {
    final json = raw as Map<String, dynamic>;
    final vb = (json['vb'] as String)
        .trim()
        .split(RegExp(r'\s+'))
        .map(double.parse)
        .toList();
    // The back view's box starts at x=718. Shifting every outline to the
    // origin means drawing and hit-testing never have to know that.
    final shift = Offset(-vb[0], -vb[1]);
    final parts = <String, List<Path>>{};
    (json['p'] as Map<String, dynamic>).forEach((slug, paths) {
      parts[slug] = [
        for (final d in paths as List) parseSvgPathData(d as String).shift(shift),
      ];
    });
    return BodyView(Size(vb[2], vb[3]), parts);
  }
}
