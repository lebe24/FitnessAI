import 'package:fitness/data/services/fitness/body_composition_service.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/scan_summary.dart';

/// Turns a body-scan result into what Analytics shows and what the server keeps.
class ScanMapper {
  ScanMapper._();

  static ScanSummary summary(BodyCompositionResult r, DateTime scannedAt) {
    final u = r.muscleMap.upperBody, c = r.muscleMap.core, l = r.muscleMap.lowerBody;
    return ScanSummary(
      scannedAt: scannedAt,
      overall: r.physiqueScores.overall,
      aesthetics: r.physiqueScores.aesthetics,
      muscleDevelopment: r.physiqueScores.muscleDevelopment,
      conditioning: r.physiqueScores.conditioning,
      posture: r.physiqueScores.posture,
      bodyFatPct: r.composition.bodyFatPct,
      muscleMassPct: r.composition.muscleMassPct,
      groupScores: {
        MuscleGroup.chest: u.chest.score,
        MuscleGroup.back: u.back.score,
        MuscleGroup.shoulders: u.shoulders.score,
        MuscleGroup.biceps: u.biceps.score,
        MuscleGroup.triceps: u.triceps.score,
        MuscleGroup.forearms: u.forearms.score,
        MuscleGroup.abs: c.abs.score,
        MuscleGroup.quads: l.quads.score,
        MuscleGroup.hamstrings: l.hamstrings.score,
        MuscleGroup.glutes: l.glutes.score,
        MuscleGroup.calves: l.calves.score,
      },
    );
  }

  /// The latest scan saved on the device, from a `BodyScanStorage` entry.
  static ScanSummary? fromStored(Map entry) {
    try {
      final data = Map<String, dynamic>.from(entry['data'] as Map);
      final at = DateTime.tryParse(entry['timestamp'] as String? ?? '') ?? DateTime.now();
      return summary(BodyCompositionResult.fromJson(data), at);
    } catch (_) {
      return null;
    }
  }

  /// The request body for `POST /body/scans`. Muscle mass in kilograms is
  /// worked out from the scan's percentage when the current weight is known.
  static Map<String, dynamic> toApi(BodyCompositionResult r, {double? weightKg, DateTime? at}) => {
        'scanned_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
        if (r.composition.bodyFatPct > 0) 'body_fat_pct': r.composition.bodyFatPct,
        if (weightKg != null && r.composition.muscleMassPct > 0)
          'muscle_mass_kg': double.parse((weightKg * r.composition.muscleMassPct / 100).toStringAsFixed(1)),
        if (weightKg != null) 'weight_kg': weightKg,
        'physique_rating': '${r.physiqueScores.overall}',
        'analysis_data': r.rawJson,
      };
}
