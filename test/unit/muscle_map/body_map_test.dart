import 'dart:io';
import 'dart:ui';

import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:flutter_test/flutter_test.dart';

/// The drawing and the muscle list are joined only by string slugs. Nothing
/// fails when they drift apart; a muscle just stops being drawn or tappable.
/// These tests read the real asset so a re-export that renames a key shows up
/// here instead of as a blank patch on the body.
void main() {
  late BodyMap map;

  setUpAll(() {
    map = BodyMapSource.parse(File(BodyMapSource.asset).readAsStringSync());
  });

  group('asset and muscle list agree', () {
    test('every muscle is drawn on the front or the back', () {
      for (final m in Muscle.all) {
        final drawn = (map.front.parts[m.slug]?.isNotEmpty ?? false) ||
            (map.back.parts[m.slug]?.isNotEmpty ?? false);
        expect(drawn, isTrue, reason: '${m.slug} has no outline in the asset');
      }
    });

    test('every part in the asset is a known muscle or silhouette', () {
      final known = {...Muscle.all.map((m) => m.slug), ...kInertBodyParts};
      for (final view in [map.front, map.back]) {
        for (final slug in view.parts.keys) {
          expect(known, contains(slug), reason: 'unhandled part: $slug');
        }
      }
    });

    test('muscle slugs are unique', () {
      final slugs = Muscle.all.map((m) => m.slug).toList();
      expect(slugs.toSet(), hasLength(slugs.length));
    });
  });

  group('parsing', () {
    test('reads the drawing sizes from the viewBoxes', () {
      expect(map.front.size, const Size(727, 1280));
      expect(map.back.size, const Size(727, 1280));
    });

    test('shifts the back view to the origin', () {
      // Its viewBox starts at x=718. Unshifted, every outline would sit off
      // to the right of its own drawing and nothing would be hit.
      var minX = double.infinity;
      for (final paths in map.back.parts.values) {
        for (final p in paths) {
          minX = p.getBounds().left < minX ? p.getBounds().left : minX;
        }
      }
      expect(minX, greaterThanOrEqualTo(0));
      expect(minX, lessThan(map.back.size.width));
    });
  });

  group('fitting into a box', () {
    test('scales to the tighter axis and centres the other', () {
      // A 727×1280 drawing in a 200×200 box is limited by height.
      final fit = BodyFit.of(const Size(727, 1280), const Size(200, 200));
      expect(fit.scale, closeTo(200 / 1280, 1e-9));
      expect(fit.offset.dy, closeTo(0, 1e-9));
      expect(fit.offset.dx, closeTo((200 - 727 * fit.scale) / 2, 1e-9));
    });

    test('converting back to drawing units undoes the fit', () {
      final fit = BodyFit.of(const Size(727, 1280), const Size(160, 340));
      const drawn = Offset(300, 640);
      final local = drawn * fit.scale + fit.offset;
      final back = fit.toDrawing(local);
      expect(back.dx, closeTo(drawn.dx, 1e-6));
      expect(back.dy, closeTo(drawn.dy, 1e-6));
    });

    test('an empty box hits nothing rather than dividing by zero', () {
      final fit = BodyFit.of(const Size(727, 1280), Size.zero);
      expect(fit.toDrawing(const Offset(10, 10)), Offset.infinite);
      expect(map.front.muscleAt(fit.toDrawing(const Offset(10, 10))), isNull);
    });
  });

  group('hit-testing', () {
    Offset insideOf(Path p) {
      // The bounds centre of a pec is inside it; scan outward if a shape is
      // concave enough that it is not.
      final b = p.getBounds();
      for (var fx = 0.5; fx < 0.9; fx += 0.05) {
        for (var fy = 0.5; fy < 0.9; fy += 0.05) {
          final pt = Offset(b.left + b.width * fx, b.top + b.height * fy);
          if (p.contains(pt)) return pt;
        }
      }
      fail('no interior point found');
    }

    test('a point inside the chest selects the chest', () {
      final pec = map.front.parts['chest']!.first;
      expect(map.front.muscleAt(insideOf(pec)), 'chest');
    });

    test('a point inside the glutes selects the glutes on the back', () {
      final glute = map.back.parts['gluteal']!.first;
      expect(map.back.muscleAt(insideOf(glute)), 'gluteal');
    });

    test('the head is silhouette, not a muscle', () {
      final head = map.front.parts['head']!.first;
      expect(map.front.muscleAt(insideOf(head)), isNull);
    });

    test('empty space selects nothing', () {
      expect(map.front.muscleAt(const Offset(2, 2)), isNull);
    });
  });
}
