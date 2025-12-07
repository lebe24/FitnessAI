import 'package:fitness/app/ui/fitness/presentation/page/workout_page.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:fitness/app/core/routes/analysis_route_wrapper.dart';
import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/ui/home/presentation/pages/home_screen.dart';
import 'package:fitness/app/ui/home/presentation/pages/settings_page.dart';
import 'package:fitness/app/ui/onboarding/presentation/onboarding_screen.dart';
import 'package:fitness/app/ui/splash/splash.dart';
import 'package:fitness/app/ui/welcome/welcome.dart';
import 'package:fitness/app/ui/nutrition/presentation/pages/nutrition_page.dart';
import 'package:fitness/app/ui/nutrition/presentation/pages/analysis_ouput_page.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_bloc.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/nutrition_analysis_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ScreenPaths {
  static String splash = '/';
  static String welcome = '/welcome';
  static String onboarding = '/onboarding';
  static String analysis = '/analysis';
  static String home = '/home';
  static String settings = '/settings';
  static String workout = '/workout';
  static String nutrition = '/nutrition';
  static String nutritionAnalysis = '/nutrition-analysis';

  static final appRouter = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: welcome,
        builder: (context, state) => Welcome(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: analysis,
        builder: (context, state) => const AnalysisPageWithData(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: workout,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return WorkoutPage(
              workoutDay: extra['workoutDay'] as WorkoutDay?,
              date: extra['date'] as DateTime?,
            );
          }
          return const WorkoutPage(
            workoutDay: null,
            date: null,
          );
        },
      ),
      GoRoute(
        path: nutrition,
        builder: (context, state) {
          final extra = state.extra;
          return BlocProvider(
            create: (context) => sl<NutritionBloc>(),
            child: extra is Map<String, dynamic> && extra['imagePath'] != null
                ? NutritionPage(
                    imagePath: extra['imagePath'] as String,
                  )
                : const NutritionPage(),
          );
        },
      ),
      GoRoute(
        path: nutritionAnalysis,
        builder: (context, state) {
          final extra = state.extra;
          return BlocProvider(
            create: (context) => sl<NutritionBloc>(),
            child: extra is Map<String, dynamic>
                ? AnalysisOutputPage(
                    analysis: extra['analysis'] as NutritionAnalysisEntity?,
                    imagePath: extra['imagePath'] as String?,
                    heroTag: extra['heroTag'] as String?,
                  )
                : const AnalysisOutputPage(),
          );
        },
      ),
    ],
  );
}

