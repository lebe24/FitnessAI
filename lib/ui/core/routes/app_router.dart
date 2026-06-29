import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/auth/views/auth_login_page.dart';
import 'package:fitness/ui/features/chat/view_models/chat_view_model.dart';
import 'package:fitness/ui/features/fitness/view_models/fitness_view_model.dart';
import 'package:fitness/ui/features/onboarding/views/chat_screen.dart';
import 'package:fitness/ui/features/fitness/views/workout_page.dart';
import 'package:fitness/ui/features/fitness/views/workout_plan_detail_page.dart';
import 'package:fitness/ui/features/home/views/home_screen.dart';
import 'package:fitness/ui/features/home/views/settings_page.dart';
import 'package:fitness/ui/features/nutrition/view_models/nutrition_view_model.dart';
import 'package:fitness/ui/features/nutrition/views/analysis_output_page.dart';
import 'package:fitness/ui/features/nutrition/views/nutrition_page.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_screen.dart';
import 'package:fitness/ui/features/splash/views/splash.dart';
import 'package:fitness/ui/features/welcome/views/welcome.dart';
import 'package:fitness/ui/core/routes/analysis_route_wrapper.dart';
import 'package:fitness/domain/models/nutrition_analysis.dart';
import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ScreenPaths {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String analysis = '/analysis';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String workout = '/workout';
  static const String nutrition = '/nutrition';
  static const String nutritionAnalysis = '/nutrition-analysis';
  static const String workoutPlanDetail = '/workout-plan-detail';
  static const String login = '/login';
  static const String chat = '/chat';
  static const String onboardingAnalysis = '/onboarding-analysis';

  static final appRouter = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: welcome, builder: (context, state) => Welcome()),
      GoRoute(path: login, builder: (context, state) => const AuthLoginPage()),
      GoRoute(path: home, builder: (context, state) => const HomePage()),
      GoRoute(path: onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: analysis, builder: (context, state) => const AnalysisPageWithData()),
      // Re-uses AnalysisPageWithData which loads onboarding data from storage
      // and provides OnboardingViewModel. AnalysisPage creates UploadViewModel
      // internally, so both providers are satisfied.
      GoRoute(
        path: onboardingAnalysis,
        builder: (context, state) => const AnalysisPageWithData(),
      ),
      GoRoute(path: settings, builder: (context, state) => const SettingsPage()),
      GoRoute(
        path: workout,
        builder: (context, state) {
          final extra = state.extra;
          return ChangeNotifierProvider(
            create: (_) => sl<FitnessViewModel>()..loadFitnessPlans(),
            child: extra is Map<String, dynamic>
                ? WorkoutPage(
                    workoutDay: extra['workoutDay'] as WorkoutDay?,
                    date: extra['date'] as DateTime?,
                  )
                : const WorkoutPage(workoutDay: null, date: null),
          );
        },
      ),
      GoRoute(
        path: nutrition,
        builder: (context, state) {
          final extra = state.extra;
          return ChangeNotifierProvider(
            create: (_) => sl<NutritionViewModel>(),
            child: extra is Map<String, dynamic> && extra['imagePath'] != null
                ? NutritionPage(imagePath: extra['imagePath'] as String)
                : const NutritionPage(),
          );
        },
      ),
      GoRoute(
        path: nutritionAnalysis,
        builder: (context, state) {
          final extra = state.extra;
          return ChangeNotifierProvider(
            create: (_) => sl<NutritionViewModel>(),
            child: extra is Map<String, dynamic>
                ? AnalysisOutputPage(
                    analysis: extra['analysis'] as NutritionAnalysisEntity?,
                    imagePath: extra['imagePath'] as String?,
                    heroTag: extra['heroTag'] as String?,
                    analysisType: extra['analysisType'] as String? ?? 'full_analysis',
                  )
                : const AnalysisOutputPage(),
          );
        },
      ),
      GoRoute(
        path: chat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChangeNotifierProvider(
            create: (_) => sl<ChatViewModel>(instanceName: 'onboarding'),
            child: ChatScreen(
              userId: extra?['userId'] as String? ?? '',
              userName: extra?['userName'] as String? ?? '',
              workoutPlan: extra?['workoutPlan'],
              onboardingData: extra?['onboardingData'] as OnboardingData?,
            ),
          );
        },
      ),
      GoRoute(
        path: workoutPlanDetail,
        builder: (context, state) {
          final extra = state.extra;
          return extra is Map<String, dynamic> && extra['storedPlan'] is StoredFitnessPlanEntity
              ? WorkoutPlanDetailPage(storedPlan: extra['storedPlan'] as StoredFitnessPlanEntity)
              : const Scaffold(body: Center(child: Text('No workout plan data available')));
        },
      ),
    ],
  );
}
