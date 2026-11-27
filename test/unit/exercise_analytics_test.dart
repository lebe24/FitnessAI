import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:fitness/data/services/analytics/exercise_analytics.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/recording_analytics.dart';

Exercise exercise({String name = 'Pull-Ups', String? notes = 'back, biceps | Lead with your chest'}) =>
    Exercise(name: name, sets: 4, reps: 'AMRAP', notes: notes);

void main() {
  late RecordingAnalytics rec;
  late DateTime clock;

  setUp(() {
    rec = RecordingAnalytics();
    Analytics.use(rec);
    clock = DateTime(2026, 11, 1, 12, 0, 0);
  });
  tearDown(() => Analytics.use(NoopAnalyticsService()));

  ExerciseAnalytics tracker([Exercise? e, int index = 2]) =>
      ExerciseAnalytics(e ?? exercise(), index, now: () => clock);

  Future<void> settle() => Future<void>.delayed(Duration.zero);
  List<String> names() => rec.events.map((e) => e.$1).toList();
  Map<String, Object?> last() => rec.events.last.$2!;

  group('what is sent about the exercise', () {
    test('position, sets and muscle — never the name', () async {
      tracker(exercise(name: "Dave's secret curl")).viewed();
      await settle();

      expect(names(), ['exercise_viewed']);
      expect(last()['exercise_index'], 2);
      expect(last()['sets'], 4);
      final everything = rec.events.map((e) => '${e.$1} ${e.$2}').join(' ');
      expect(everything.contains('Dave'), isFalse);
      expect(everything.contains('secret'), isFalse);
    });

    test('the muscle comes from the plan notes, like the muscle map', () async {
      final expected =
          MuscleCoverage.musclesFor(name: 'Pull-Ups', notes: 'back, biceps | Lead with your chest').first;
      tracker().viewed();
      await settle();
      expect(last()['muscle'], expected);
    });

    test('an exercise nothing recognises is reported as unknown', () async {
      tracker(exercise(name: 'Zzyzx maneuver', notes: null)).viewed();
      await settle();
      expect(last()['muscle'], 'unknown');
    });

    test('every exercise event carries the same three context fields', () async {
      final t = tracker();
      t.viewed();
      t.logOpened(hadPrevious: true);
      t.sameAsLast();
      t.logIncomplete(2);
      t.logSaved();
      t.logDismissed();
      t.logSaveFailed();
      await settle();
      for (final (name, props) in rec.events) {
        expect(props!.keys, containsAll(['exercise_index', 'sets', 'muscle']), reason: name);
      }
    });
  });

  group('the log dialog', () {
    test('records opening, with whether there was a last time to show', () async {
      tracker().logOpened(hadPrevious: false);
      await settle();
      expect(names(), ['exercise_log_opened']);
      expect(last()['had_previous'], false);
    });

    test('saving reports whether voice and "same as last time" were used', () async {
      final t = tracker();
      t.logOpened(hadPrevious: true);
      t.voice('started');
      t.voice('parsed', sets: 3);
      t.sameAsLast();
      rec.events.clear();
      t.logSaved();
      await settle();
      expect(last()['used_voice'], true);
      expect(last()['used_last_time'], true);
    });

    test('a started voice attempt that never parsed does not count as used', () async {
      final t = tracker();
      t.logOpened(hadPrevious: false);
      t.voice('started');
      t.voice('failed');
      rec.events.clear();
      t.logSaved();
      await settle();
      expect(last()['used_voice'], false);
    });

    test('the flags reset each time the dialog opens', () async {
      final t = tracker();
      t.logOpened(hadPrevious: true);
      t.sameAsLast();
      t.logOpened(hadPrevious: true); // opened again
      rec.events.clear();
      t.logSaved();
      await settle();
      expect(last()['used_last_time'], false);
    });

    test('voice records only the outcome, never what was said', () async {
      tracker().voice('parsed', sets: 3);
      await settle();
      expect(last().keys.toSet(), {'result', 'sets_filled'});
    });

    test('incomplete saves say how many sets were missing', () async {
      tracker().logIncomplete(3);
      await settle();
      expect(last()['missing_sets'], 3);
    });
  });

  group('ending the visit', () {
    test('Mark Complete reports how long the visit lasted and whether it was logged', () async {
      final t = tracker();
      clock = clock.add(const Duration(minutes: 6, seconds: 12));
      t.completed(logged: true);
      await settle();
      expect(names(), ['exercise_completed']);
      expect(last()['seconds_on_page'], 372);
      expect(last()['logged'], true);
    });

    test('leaving without completing is reported as left', () async {
      final t = tracker();
      clock = clock.add(const Duration(seconds: 45));
      t.left(logged: false);
      await settle();
      expect(names(), ['exercise_left']);
      expect(last()['seconds_on_page'], 45);
    });

    test('a completed exercise is not also reported as left when the page closes', () async {
      final t = tracker();
      t.completed(logged: true);
      t.left(logged: true); // what dispose() does
      await settle();
      expect(names(), ['exercise_completed']);
    });

    test('a visit ends once', () async {
      final t = tracker();
      t.left(logged: false);
      t.left(logged: false);
      t.completed(logged: false);
      await settle();
      expect(names(), ['exercise_left']);
    });

    test('the leave prompt records the choice', () async {
      tracker().leavePrompt('discard');
      await settle();
      expect(last()['choice'], 'discard');
    });
  });

  group('history and tutorials', () {
    test('history outcomes: ok, empty and failed', () async {
      final t = tracker();
      t.historyLoaded(null);
      t.historyLoaded(ExerciseHistory.empty);
      await settle();
      expect(rec.events.map((e) => e.$2!['status']), ['failed', 'empty']);
    });

    test('tutorials report success, cache use and count', () async {
      final t = tracker();
      t.tutorialsLoaded(success: true, count: 8);
      t.tutorialsLoaded(success: true, cached: true);
      t.tutorialsLoaded(success: false);
      await settle();
      expect(rec.events[0].$2, {'success': true, 'cached': false, 'count': 8});
      expect(rec.events[1].$2!['cached'], true);
      expect(rec.events[2].$2!['success'], false);
    });
  });
}
