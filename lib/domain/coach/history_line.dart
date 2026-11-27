import 'package:fitness/domain/models/exercise_history.dart';

/// One visit to an exercise in a line: `4 × 10 @ 28 kg`. When the reps differ
/// between sets it says how many sets and the best one: `3 sets · best 8 × 60 kg`.
String historyLine(ExerciseHistoryEntry entry) {
  final sets = entry.sets;
  if (sets.isEmpty) return '–';
  final best = entry.bestSet ?? sets.first;
  String amount(int? reps, int? seconds) => seconds != null ? '${seconds}s' : '${reps ?? 0}';
  final weight = best.weightKg;
  final load = weight == null || weight == 0 ? '' : ' @ ${formatKg(weight)} kg';
  final same = sets.every((s) =>
      s.reps == sets.first.reps && s.durationSec == sets.first.durationSec && s.weightKg == sets.first.weightKg);
  if (same) return '${sets.length} × ${amount(best.reps, best.durationSec)}$load';
  final times = weight == null || weight == 0 ? '' : ' × ${formatKg(weight)} kg';
  return '${sets.length} sets · best ${amount(best.reps, best.durationSec)}$times';
}
