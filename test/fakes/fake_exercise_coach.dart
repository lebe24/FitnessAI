import 'dart:async';

import 'package:fitness/data/services/coach/exercise_coach_service.dart';

/// A coach that answers from a script. By default it picks the first
/// candidates, as a working model would.
class FakeExerciseCoach implements ExerciseCoach {
  final requests = <ExerciseCoachRequest>[];
  ExerciseCoachError? error;
  Completer<void>? gate;

  @override
  Future<CoachAnswer> ask(ExerciseCoachRequest r) async {
    requests.add(r);
    if (gate != null) await gate!.future;
    if (error != null) return CoachAnswer.fallback(r, error);
    return CoachAnswer(
      note: 'Coach note about this set.',
      sessionAdvice: 'Coach advice about the session.',
      picks: r.candidates.take(r.ask == CoachAsk.workout ? 3 : 2).toList(),
      fromModel: true,
    );
  }
}
