import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/data/services/share/image_sharer.dart';
import 'package:fitness/domain/models/session_share.dart';
import 'package:fitness/ui/features/analytic/history_samples.dart';
import 'package:fitness/ui/features/analytic/views/session_detail_page.dart';
import 'package:fitness/ui/features/analytic/views/share/session_share_graphic.dart';
import 'package:fitness/ui/features/analytic/views/share/session_share_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../fakes/recording_analytics.dart';

/// The sizes of the pictures that were captured.
final _captured = <Size>[];

Future<Uint8List> _fakeCapture(RenderRepaintBoundary picture) async {
  _captured.add(picture.size);
  return Uint8List.fromList([137, 80, 78, 71]);
}

class _Sharer implements ImageSharer {
  final shared = <(Uint8List, String, Rect?)>[];
  Object? error;
  ShareOutcome outcome = ShareOutcome.shared;

  @override
  Future<ShareOutcome> share(Uint8List png, {required String fileName, Rect? origin}) async {
    if (error != null) throw error!;
    shared.add((png, fileName, origin));
    return outcome;
  }
}

final _share = SessionShare.of(HistorySamples.all.first, history: HistorySamples.all);

Future<BodyMap> _map() async => BodyMapSource.parse(File(BodyMapSource.asset).readAsStringSync());

Future<_Sharer> _open(WidgetTester t, {SessionShare? share, bool imperial = false, _Sharer? sharer}) async {
  final s = sharer ?? _Sharer();
  final map = await t.runAsync(_map);
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    home: SessionSharePage(
      share: share ?? _share,
      imperial: imperial,
      sharer: s,
      loadMap: () async => map!,
      capture: _fakeCapture,
    ),
  ));
  await t.pumpAndSettle();
  return s;
}

Future<void> _tapShare(WidgetTester t) async {
  await t.tap(find.text('Share'));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the picture', () {
    testWidgets('carries the workout\'s numbers', (t) async {
      await _open(t);
      expect(find.text('Legs & Core'), findsOneWidget);
      expect(find.text('9,420'), findsOneWidget);
      expect(find.text('TOTAL WEIGHT MOVED'), findsOneWidget);
      expect(find.text('58'), findsOneWidget);
      expect(find.text('MIN'), findsOneWidget);
      expect(find.text('TOP SETS'), findsOneWidget);
      expect(find.text('Tracked with BeFit'), findsOneWidget);
      expect(find.text('THU · NOV 20, 2025'), findsOneWidget);
    });

    testWidgets('shows pounds when that is the setting', (t) async {
      await _open(t, imperial: true);
      expect(find.text('lb'), findsOneWidget);
      expect(find.textContaining(' lb × '), findsWidgets);
      expect(find.textContaining(' kg'), findsNothing);
    });

    testWidgets('marks new bests', (t) async {
      final share = SessionShare(
        title: 'Push',
        date: _day,
        sets: 3,
        volumeKg: 500,
        lifts: [ShareLift(name: 'Bench Press', weightKg: 100, reps: 5, isBest: true)],
      );
      await _open(t, share: share);
      expect(find.text('1 NEW BEST'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
      expect(find.text('100 kg × 5'), findsOneWidget);
    });

    testWidgets('a bodyweight workout leads with reps', (t) async {
      final share = SessionShare(
        title: 'Calisthenics',
        date: _day,
        sets: 2,
        reps: 27,
        lifts: [ShareLift(name: 'Push-up', reps: 15)],
      );
      await _open(t, share: share);
      expect(find.text('TOTAL REPS'), findsOneWidget);
      expect(find.text('27'), findsOneWidget);
      expect(find.text('15 reps'), findsOneWidget);
      expect(find.text('MIN'), findsNothing); // no duration recorded
    });

    for (final format in ShareFormat.values) {
      testWidgets('nothing overflows in the ${format.name} shape with long names and big numbers', (t) async {
        final share = SessionShare(
          title: 'An extremely long workout name that goes on and on and on',
          date: _day,
          durationMins: 1234,
          exercises: 99,
          sets: 999,
          reps: 99999,
          volumeKg: 9999999,
          muscles: ['Quads', 'Hamstrings', 'Lower back'],
          lifts: [
            for (var i = 0; i < 6; i++)
              ShareLift(name: 'Single-arm dumbbell Romanian deadlift with a pause', weightKg: 1000, reps: 100, isBest: true),
          ],
        );
        await _open(t, share: share, imperial: true);
        await t.tap(find.text(format.label));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(t.getSize(find.byType(SessionShareGraphic)), format.size);
      });
    }
  });

  group('capturing', () {
    testWidgets('gives a PNG three times the layout size, 1080 pixels wide', (t) async {
      for (final format in ShareFormat.values) {
        final key = GlobalKey();
        await t.pumpWidget(Center(
          child: FittedBox(
            child: RepaintBoundary(key: key, child: SizedBox.fromSize(size: format.size, child: const ColoredBox(color: Colors.black))),
          ),
        ));
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await t.runAsync(() async {
          final png = await capturePng(boundary, pixelRatio: SessionSharePage.pixelRatio);
          expect(png.sublist(1, 4), 'PNG'.codeUnits);
          final codec = await ui.instantiateImageCodec(png);
          return (await codec.getNextFrame()).image;
        });
        expect((image!.width, image.height),
            format == ShareFormat.story ? (1080, 1920) : (1080, 1350));
      }
    });
  });

  group('sharing', () {
    setUp(_captured.clear);

    testWidgets('sends the story picture, named by date', (t) async {
      final s = await _open(t);
      await _tapShare(t);

      final (png, name, origin) = s.shared.single;
      expect(png, isNotEmpty);
      expect(name, 'befit-workout-2025-11-20-story.png');
      expect(origin, isNotNull);
      expect(_captured.single, ShareFormat.story.size);
    });

    testWidgets('and the post shape when chosen', (t) async {
      final s = await _open(t);
      await t.tap(find.text('Post'));
      await t.pumpAndSettle();
      await _tapShare(t);

      expect(_captured.single, ShareFormat.post.size);
      expect(s.shared.single.$2, endsWith('-post.png'));
    });

    testWidgets('a failure is reported and can be tried again', (t) async {
      final s = _Sharer()..error = Exception('no share menu');
      await _open(t, sharer: s);
      await _tapShare(t);
      expect(find.text('Could not share the picture. Please try again.'), findsOneWidget);

      s.error = null;
      ScaffoldMessenger.of(t.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await t.pumpAndSettle();
      await _tapShare(t);
      expect(s.shared, hasLength(1));
    });

    testWidgets('the button waits for the body drawing', (t) async {
      final map = Completer<BodyMap>();
      final s = _Sharer();
      await t.pumpWidget(MaterialApp(
        home: SessionSharePage(share: _share, imperial: false, sharer: s, loadMap: () => map.future),
      ));
      await t.pump();
      await t.tap(find.text('Share'), warnIfMissed: false);
      await t.pump();
      expect(s.shared, isEmpty);
    });

    testWidgets('analytics says it was shared, not what was on it', (t) async {
      final rec = RecordingAnalytics();
      Analytics.use(rec);
      addTearDown(() => Analytics.use(NoopAnalyticsService()));

      await _open(t);
      await _tapShare(t);

      final events = [for (final e in rec.events) e];
      expect(events.map((e) => e.$1), containsAll(['session_share_opened', 'session_share_finished']));
      expect(events.last.$2, {'format': 'story', 'outcome': 'shared'});
      final all = events.map((e) => '${e.$1} ${e.$2}').join('\n');
      for (final secret in ['Legs', 'Squat', '9420', '9,420']) {
        expect(all.contains(secret), isFalse, reason: secret);
      }
    });
  });

  group('the floating button', () {
    testWidgets('opens the share screen from a session', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: SessionDetailPage(session: HistorySamples.all.first, imperial: false, history: HistorySamples.all),
      ));
      await t.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await t.tap(find.byType(FloatingActionButton));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(find.byType(SessionSharePage), findsOneWidget);
    });

    testWidgets('is absent for a session with nothing logged', (t) async {
      await t.pumpWidget(MaterialApp(
        home: SessionDetailPage(
          session: WorkoutSessionModel(sessionDate: DateTime(2025, 11, 3), dayLabel: 'Empty'),
          imperial: false,
        ),
      ));
      await t.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}

final _day = DateTime(2026, 11, 24);
