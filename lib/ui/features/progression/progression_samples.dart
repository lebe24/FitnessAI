// Sample data for the design-review preview only. The app never reads this.
import 'package:fitness/domain/progression/progression_proposal.dart';

class ProgressionSamples {
  static const ready = ProgressionProposal(
    planName: 'Push · Pull · Legs',
    goal: 'Build muscle',
    fromVersion: 5,
    toVersion: 6,
    weeks: 4,
    sessionsAnalysed: 14,
    adherence: 0.86,
    newPersonalBests: 5,
    isDeload: false,
    changes: [
      PlannedChange(
        day: 'Mon', dayFocus: 'Push',
        exercise: 'Barbell Bench Press', kind: ChangeKind.load,
        before: '3 × 8–10 · 60 kg', after: '3 × 8–10 · 62.5 kg', badge: '+2.5 kg',
        reason: 'You hit 10 reps on every set in your last 2 sessions.',
      ),
      PlannedChange(
        day: 'Mon', dayFocus: 'Push',
        exercise: 'Incline Dumbbell Press', kind: ChangeKind.reps,
        before: '3 × 8 · 22 kg', after: '3 × 9 · 22 kg', badge: '+1 rep',
        reason: 'You reached 8 reps on every set. Reps first, then weight.',
      ),
      PlannedChange(
        day: 'Mon', dayFocus: 'Push',
        exercise: 'Lateral Raise', kind: ChangeKind.sets,
        before: '3 × 12–15 · 8 kg', after: '4 × 12–15 · 8 kg', badge: '+1 set',
        reason: 'Shoulders are your least-trained muscle and you are recovering well.',
      ),
      PlannedChange(
        day: 'Mon', dayFocus: 'Push',
        exercise: 'Overhead Press', kind: ChangeKind.hold,
        before: '3 × 8 · 40 kg', after: '3 × 8 · 40 kg', badge: 'Hold',
        reason: 'Set 3 fell to 6 reps last session. Repeat it before adding weight.',
      ),
      PlannedChange(
        day: 'Wed', dayFocus: 'Pull',
        exercise: 'Conventional Deadlift', kind: ChangeKind.load,
        before: '3 × 5 · 100 kg', after: '3 × 5 · 105 kg', badge: '+5 kg',
        reason: 'All 15 reps done at 100 kg, twice in a row.',
      ),
      PlannedChange(
        day: 'Wed', dayFocus: 'Pull',
        exercise: 'Lat Pulldown', kind: ChangeKind.reps,
        before: '3 × 10 · 50 kg', after: '3 × 11 · 50 kg', badge: '+1 rep',
        reason: 'You have matched 10 reps for 3 weeks. Time to push the reps.',
      ),
      PlannedChange(
        day: 'Fri', dayFocus: 'Legs',
        exercise: 'Back Squat', kind: ChangeKind.load,
        before: '4 × 6–8 · 80 kg', after: '4 × 6–8 · 85 kg', badge: '+5 kg',
        reason: 'Top of the rep range on every set across 3 sessions.',
      ),
      PlannedChange(
        day: 'Fri', dayFocus: 'Legs',
        exercise: 'Seated Leg Curl', kind: ChangeKind.sets,
        before: '3 × 12 · 35 kg', after: '4 × 12 · 35 kg', badge: '+1 set',
        reason: 'Hamstrings trail your quads. A fourth set evens them out.',
      ),
      PlannedChange(
        day: 'Fri', dayFocus: 'Legs',
        exercise: 'Walking Lunges', kind: ChangeKind.deload,
        before: '3 × 10 · 20 kg', after: '3 × 10 · 18 kg', badge: '−10%',
        reason: 'No progress for 3 sessions. A lighter block usually breaks a stall.',
      ),
    ],
  );

  static const deload = ProgressionProposal(
    planName: 'Push · Pull · Legs',
    goal: 'Build muscle',
    fromVersion: 6,
    toVersion: 7,
    weeks: 6,
    sessionsAnalysed: 17,
    adherence: 0.94,
    newPersonalBests: 3,
    isDeload: true,
    changes: [
      PlannedChange(
        day: 'Mon', dayFocus: 'Push',
        exercise: 'Barbell Bench Press', kind: ChangeKind.deload,
        before: '3 × 8–10 · 62.5 kg', after: '2 × 8–10 · 55 kg', badge: '−12%',
        reason: 'Week 6 of the block. Fewer sets and lighter load let you recover.',
      ),
      PlannedChange(
        day: 'Wed', dayFocus: 'Pull',
        exercise: 'Conventional Deadlift', kind: ChangeKind.deload,
        before: '3 × 5 · 105 kg', after: '2 × 5 · 90 kg', badge: '−14%',
        reason: 'Heavy pulls build up the most fatigue, so they drop the most.',
      ),
      PlannedChange(
        day: 'Fri', dayFocus: 'Legs',
        exercise: 'Back Squat', kind: ChangeKind.deload,
        before: '4 × 6–8 · 85 kg', after: '3 × 6–8 · 75 kg', badge: '−12%',
        reason: 'Same load drop as your other lifts, so the week stays balanced.',
      ),
    ],
  );

  static final history = [
    AppliedUpdate(
      version: 5,
      date: DateTime(2026, 11, 17),
      changeCount: 6,
      highlights: ['Bench +2.5 kg', 'Squat +5 kg', 'Row +1 rep'],
    ),
    AppliedUpdate(
      version: 4,
      date: DateTime(2026, 11, 3),
      changeCount: 5,
      highlights: ['Deadlift +5 kg', 'Lat Pulldown +1 rep'],
      wasAutomatic: true,
    ),
    AppliedUpdate(
      version: 3,
      date: DateTime(2026, 10, 20),
      changeCount: 4,
      highlights: ['Deload week', 'Squat −10%', 'Bench −10%'],
      isDeload: true,
    ),
    AppliedUpdate(
      version: 2,
      date: DateTime(2026, 10, 6),
      changeCount: 7,
      highlights: ['Bench +2.5 kg', 'Curl +1 set'],
      wasAutomatic: true,
    ),
  ];
}
