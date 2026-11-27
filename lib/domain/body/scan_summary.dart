import 'package:equatable/equatable.dart';
import 'package:fitness/domain/body/body_models.dart';

/// The numbers from the latest body scan that the Analytics screen uses.
class ScanSummary extends Equatable {
  final DateTime scannedAt;
  final int overall;
  final int aesthetics;
  final int muscleDevelopment;
  final int conditioning;
  final int posture;
  final double bodyFatPct;
  final double muscleMassPct;

  /// 1–10 per muscle group, the scale the scan uses. Groups the scan does not
  /// score (traps) are absent.
  final Map<MuscleGroup, int> groupScores;

  const ScanSummary({
    required this.scannedAt,
    required this.overall,
    required this.aesthetics,
    required this.muscleDevelopment,
    required this.conditioning,
    required this.posture,
    required this.bodyFatPct,
    required this.muscleMassPct,
    required this.groupScores,
  });

  @override
  List<Object?> get props => [scannedAt, overall, aesthetics, muscleDevelopment, conditioning,
        posture, bodyFatPct, muscleMassPct, groupScores];
}
