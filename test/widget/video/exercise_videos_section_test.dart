import 'dart:async';

import 'package:fitness/data/services/video/form_analysis_runner.dart';
import 'package:fitness/data/services/video/form_analysis_service.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/ui/features/video/views/exercise_videos_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/video_test_env.dart';

void main() {
  late VideoTestEnv env;
  final now = DateTime(2026, 11, 2, 12);

  setUp(() async => env = await VideoTestEnv.create());
  tearDown(() async => env.dispose());

  Widget host({
    bool locked = false,
    Future<void> Function()? onAdd,
    String exercise = 'Pull-Ups',
  }) =>
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ExerciseVideosSection(
              exerciseName: exercise,
              muscles: const ['upper-back', 'biceps'],
              storage: env.storage,
              runner: env.runner,
              analysisLocked: () => locked,
              onAdd: onAdd,
              now: now,
            ),
          ),
        ),
      );

  Future<void> show(WidgetTester t, {bool locked = false, Future<void> Function()? onAdd}) async {
    await t.pumpWidget(host(locked: locked, onAdd: onAdd));
    await t.pump();
  }

  group('with no videos', () {
    testWidgets('invites the user to record a set', (t) async {
      await show(t);
      expect(find.text('My Videos'), findsOneWidget);
      expect(find.text('Record a set to check your form'), findsOneWidget);
      expect(find.text('Add video'), findsOneWidget);
      expect(find.text('Tips'), findsNothing, reason: 'tips and Add move to the header once there are videos');
    });

    testWidgets('Add video starts the add flow', (t) async {
      var added = 0;
      await show(t, onAdd: () async => added++);
      await t.tap(find.text('Add video'));
      await t.pump();
      expect(added, 1);
    });

    testWidgets('is not named like the YouTube tutorials', (t) async {
      await show(t);
      expect(find.textContaining('Tutorial'), findsNothing);
    });
  });

  group('with videos', () {
    testWidgets('shows a card per video with its date and length', (t) async {
      await t.runAsync(() async {
        await env.add('Pull-Ups', at: DateTime(2026, 11, 1, 9), durationMs: 42000);
        await env.add('Pull-Ups', at: DateTime(2026, 10, 20), durationMs: 75000);
      });
      await show(t);
      await t.pump();
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('20 Oct'), findsOneWidget);
      expect(find.text('0:42'), findsOneWidget);
      expect(find.text('1:15'), findsOneWidget);
      expect(find.text('Analyse'), findsNWidgets(2));
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Tips'), findsOneWidget);
    });

    testWidgets('shows only this exercise\'s videos, matching spelling variants', (t) async {
      await t.runAsync(() async {
        await env.add('pull up');
        await env.add('Bench Press');
      });
      await show(t);
      await t.pump();
      expect(find.text('Analyse'), findsOneWidget);
    });

    testWidgets('a new video appears without the page being rebuilt', (t) async {
      await show(t);
      expect(find.text('Record a set to check your form'), findsOneWidget);
      await t.runAsync(() => env.add('Pull-Ups'));
      await t.pump();
      await t.pump();
      expect(find.text('Record a set to check your form'), findsNothing);
      expect(find.text('Analyse'), findsOneWidget);
    });

    testWidgets('a deleted video disappears', (t) async {
      late ExerciseVideo v;
      await t.runAsync(() async => v = await env.add('Pull-Ups'));
      await show(t);
      await t.pump();
      expect(find.text('Analyse'), findsOneWidget);
      await t.runAsync(() => env.storage.delete(v.id));
      await t.pump();
      await t.pump();
      expect(find.text('Analyse'), findsNothing);
      expect(find.text('Record a set to check your form'), findsOneWidget);
    });

    testWidgets('an analysed video shows its rating instead of Analyse', (t) async {
      await t.runAsync(() async => env.add('Pull-Ups',
          analysis: const FormAnalysis(overallScore: 8, confidence: Confidence.high)));
      await show(t);
      await t.pump();
      expect(find.text('8/10'), findsOneWidget);
      expect(find.text('Analyse'), findsNothing);
    });

    testWidgets('a low-confidence rating is marked with a ~', (t) async {
      await t.runAsync(() async => env.add('Pull-Ups',
          analysis: const FormAnalysis(overallScore: 7, confidence: Confidence.low)));
      await show(t);
      await t.pump();
      expect(find.text('~7/10'), findsOneWidget);
    });

    testWidgets('a locked analysis shows a lock, not a different label', (t) async {
      await t.runAsync(() async => env.add('Pull-Ups'));
      await show(t, locked: true);
      await t.pump();
      expect(find.text('Analyse'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });
  });

  group('while analysing', () {
    Future<AnalysisJob> startAndWait(WidgetTester t, ExerciseVideo v) async {
      late AnalysisJob job;
      await t.runAsync(() async {
        job = env.runner.start(v);
        while (job.phase != AnalysisPhase.analysing) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await t.pump();
      return job;
    }

    testWidgets('the card dims and offers Cancel', (t) async {
      late ExerciseVideo v;
      await t.runAsync(() async => v = await env.add('Pull-Ups'));
      await show(t);
      await t.pump();
      env.service.gate = Completer<void>();
      final job = await startAndWait(t, v);
      expect(job.isRunning, isTrue);
      expect(find.text('Analysing…'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Analyse'), findsNothing);

      env.service.gate!.complete();
      await t.runAsync(() async {
        while (job.isRunning) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await t.pump();
      await t.pump();
      expect(find.text('Analysing…'), findsNothing);
    });

    testWidgets('Cancel stops the analysis and the card goes back to Analyse', (t) async {
      late ExerciseVideo v;
      await t.runAsync(() async => v = await env.add('Pull-Ups'));
      await show(t);
      await t.pump();
      env.service.gate = Completer<void>();
      final job = await startAndWait(t, v);

      await t.tap(find.text('Cancel'));
      await t.pump();
      env.service.gate!.complete();
      await t.runAsync(() async {
        while (job.isRunning) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await t.pump();
      await t.pump();
      expect(job.phase, AnalysisPhase.cancelled);
      expect(find.text('Analysing…'), findsNothing);
      expect(find.text('Analyse'), findsOneWidget, reason: 'a cancelled run is not a failure');
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('a finished analysis replaces Analyse with the rating', (t) async {
      late ExerciseVideo v;
      await t.runAsync(() async => v = await env.add('Pull-Ups'));
      await show(t);
      await t.pump();
      late AnalysisJob job;
      await t.runAsync(() async {
        job = env.runner.start(v);
        while (job.isRunning) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await t.pump();
      await t.pump();
      expect(job.phase, AnalysisPhase.done);
      expect(find.text('7/10'), findsOneWidget);
    });
  });

  group('after a failure', () {
    testWidgets('offers Retry', (t) async {
      late ExerciseVideo v;
      await t.runAsync(() async => v = await env.add('Pull-Ups'));
      await show(t);
      await t.pump();
      env.service.error =
          const FormAnalysisException(FormAnalysisFailure.couldNotAnalyse, 'bad');
      await t.runAsync(() async {
        final job = env.runner.start(v);
        while (job.isRunning) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await t.pump();
      await t.pump();
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Analyse'), findsNothing);
    });

    testWidgets('over the monthly limit says so instead of offering a retry', (t) async {
      late ExerciseVideo v;
      await t.runAsync(() async => v = await env.add('Pull-Ups'));
      await show(t);
      await t.pump();
      env.service.error = const FormAnalysisException(
          FormAnalysisFailure.monthlyCap, 'used', used: 30, cap: 30);
      await t.runAsync(() async {
        final job = env.runner.start(v);
        while (job.isRunning) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await t.pump();
      await t.pump();
      expect(find.text('Limit reached'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });
}
