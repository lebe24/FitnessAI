import 'package:fitness/domain/use_cases/storage/get_all_fitness_plans_usecase.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/routes/app_router.dart';

/// Decides where an authenticated user lands when the app opens or after
/// login.
///
/// A user can quit during onboarding on the analysis page — before uploading
/// a photo and generating a workout plan. Without this gate they'd reopen the
/// app straight into the main tabs with no plan anywhere. The gate checks the
/// locally stored fitness plans and routes plan-less users back to the
/// analysis page to finish generating one.
class PlanGate {
  /// `ScreenPaths.home` when at least one workout plan exists,
  /// `ScreenPaths.analysis` when none has been generated yet.
  static Future<String> resolvedHome() async {
    try {
      final plans = await sl<GetAllFitnessPlansUsecase>()();
      return plans.isEmpty ? ScreenPaths.analysis : ScreenPaths.home;
    } catch (_) {
      // Fail open: a storage error must never trap the user outside the app.
      return ScreenPaths.home;
    }
  }
}
