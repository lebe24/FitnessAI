import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:flutter_test/flutter_test.dart';

PlannedChange _load({double from = 60, double to = 65}) => PlannedChange(
      day: 'Mon', dayFocus: 'Push', exercise: 'Bench Press', kind: ChangeKind.load,
      before: '3 × 8-10 · 60 kg', after: '3 × 8-10 · 65 kg', badge: '+5 kg',
      reason: 'You hit 10 reps.', dayIndex: 0, exerciseIndex: 0,
      updated: _bench(to), previousKg: from,
    );

PlannedChange _reps() => PlannedChange(
      day: 'Mon', dayFocus: 'Push', exercise: 'Row', kind: ChangeKind.reps,
      before: '3 × 8 · 50 kg', after: '3 × 9 · 50 kg', badge: '+1 rep', reason: 'Reps first.',
      dayIndex: 0, exerciseIndex: 1, updated: _row(), previousKg: 50,
    );

PlannedChange _deload() => PlannedChange(
      day: 'Fri', dayFocus: 'Legs', exercise: 'Squat', kind: ChangeKind.deload,
      before: '4 × 6 · 100 kg', after: '4 × 6 · 90 kg', badge: '−10%', reason: 'Stalled.',
      dayIndex: 0, exerciseIndex: 2, updated: _squat(), previousKg: 100,
    );

PlannedChange _hold() => const PlannedChange(
      day: 'Mon', dayFocus: 'Push', exercise: 'OHP', kind: ChangeKind.hold,
      before: '3 × 8 · 40 kg', after: '3 × 8 · 40 kg', badge: 'Hold', reason: 'Missed a set.');

Exercise _bench(double kg) => Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: kg);
Exercise _row() => const Exercise(name: 'Row', sets: 3, reps: '9', targetKg: 50);
Exercise _squat() => const Exercise(name: 'Squat', sets: 4, reps: '6', targetKg: 90);

ProgressionProposal _proposal(List<PlannedChange> c) => ProgressionProposal(
      planName: 'Push', goal: 'Build muscle', fromVersion: 1, toVersion: 2, weeks: 6,
      sessionsAnalysed: 10, adherence: 0.8, newPersonalBests: 1, isDeload: false, changes: c);

CoachResult _result(Map<String, CoachDecision> d, {String? note, bool reviewed = true}) =>
    CoachResult(decisions: d, note: note, reviewed: reviewed);

void main() {
  group('applying the coach\'s decisions', () {
    test('approval keeps the change and adds the coach\'s sentence', () {
      final out = ProgressionEngine.applyCoach(
        _proposal([_load()]),
        _result({'c0': const CoachDecision(CoachVerdict.approve, 'Earned it.')}, note: 'Looks good.'),
      );
      final c = out.changes.single;
      expect(c.kind, ChangeKind.load);
      expect(c.updated!.targetKg, 65);
      expect(c.coachReason, 'Earned it.');
      expect(c.coachAdjusted, isFalse);
      expect(out.coachState, CoachState.reviewed);
      expect(out.coachNote, 'Looks good.');
    });

    test('softening halves a weight step, rounded to half a kilo', () {
      final out = ProgressionEngine.applyCoach(
        _proposal([_load(from: 60, to: 65)]),
        _result({'c0': const CoachDecision(CoachVerdict.soften, 'Smaller step.')}),
      );
      final c = out.changes.single;
      expect(c.updated!.targetKg, 62.5);
      expect(c.badge, '+2.5 kg');
      expect(c.after, '3 × 8-10 · 62.5 kg');
      expect(c.kind, ChangeKind.load);
      expect(c.coachAdjusted, isTrue);
    });

    test('a step too small to halve becomes a hold', () {
      final out = ProgressionEngine.applyCoach(
        _proposal([_load(from: 60, to: 60.5)]),
        _result({'c0': const CoachDecision(CoachVerdict.soften)}),
      );
      expect(out.changes.single.isHold, isTrue);
    });

    test('softening a rep or set change holds it, since there is nothing smaller', () {
      final out = ProgressionEngine.applyCoach(
        _proposal([_reps()]),
        _result({'c0': const CoachDecision(CoachVerdict.soften, 'Wait a week.')}),
      );
      final c = out.changes.single;
      expect(c.isHold, isTrue);
      expect(c.updated, isNull);
      expect(c.after, c.before);
    });

    test('a veto holds the exercise and says why', () {
      final out = ProgressionEngine.applyCoach(
        _proposal([_load(), _reps()]),
        _result({'c0': const CoachDecision(CoachVerdict.veto, 'Too much for your legs this week.')}),
      );
      final c = out.changes.first;
      expect(c.isHold, isTrue);
      expect(c.badge, 'Held');
      expect(c.reason, 'Too much for your legs this week.');
      expect(c.coachVerdict, CoachVerdict.veto);
      expect(out.actionable.length, 1);
    });

    test('a recovery week is never changed', () {
      final out = ProgressionEngine.applyCoach(
        _proposal([_deload()]),
        _result({'c0': const CoachDecision(CoachVerdict.veto)}),
      );
      expect(out.changes.single.kind, ChangeKind.deload);
      expect(out.changes.single.updated, isNotNull);
    });

    test('holds pass through and ids skip nothing', () {
      final out = ProgressionEngine.applyCoach(
        _proposal([_hold(), _load()]),
        _result({'c1': const CoachDecision(CoachVerdict.veto)}),
      );
      expect(out.changes.first.exercise, 'OHP');
      expect(out.changes.last.isHold, isTrue);
    });

    test('a missing decision leaves the change as proposed', () {
      final out = ProgressionEngine.applyCoach(_proposal([_load()]), _result({}));
      expect(out.changes.single.updated!.targetKg, 65);
    });

    test('when the coach could not review, nothing changes and the state says so', () {
      final p = _proposal([_load()]);
      final out = ProgressionEngine.applyCoach(p, _result({}, reviewed: false));
      expect(out.coachState, CoachState.unavailable);
      expect(out.changes.single.updated!.targetKg, 65);
    });

    test('applying a vetoed proposal leaves that exercise as it was', () {
      // c0 held by the coach, so the plan keeps its target.
      final p = ProgressionEngine.applyCoach(
        _proposal([_load()]),
        _result({'c0': const CoachDecision(CoachVerdict.veto)}),
      );
      expect(p.changes.single.updated, isNull);
    });
  });
}
