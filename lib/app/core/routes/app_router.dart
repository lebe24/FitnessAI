import 'package:fitness/app/ui/fitness/page/sample_page.dart';
import 'package:fitness/app/ui/home/presentation/pages/analysis_page.dart';
import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/ui/home/presentation/pages/home_screen.dart';
import 'package:fitness/app/ui/home/presentation/pages/settings_page.dart';
import 'package:fitness/app/ui/onboarding/presentation/onboarding_screen.dart';
import 'package:fitness/app/ui/splash/splash.dart';
import 'package:fitness/app/ui/welcome/welcome.dart';

class ScreenPaths {
  static String splash = '/';
  static String welcome = '/welcome';
  static String onboarding = '/onboarding';
  static String analysis = '/analysis';
  static String home = '/home';
  static String settings = '/settings';

  static final appRouter = GoRouter(
    initialLocation: analysis,
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
        builder: (context, state) =>  SamplePage(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}

