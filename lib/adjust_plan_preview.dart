// Design-review entry point for the Adjust Workout Plan screen. Not part of the
// app: it shows the screen with sample answers and saves nothing.
//
//   flutter run -t lib/adjust_plan_preview.dart -d <device>
//
// On web, open a state with ?screen=default|empty|imperial|advanced
import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/profile/views/adjust_workout_plan_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    final screen = Uri.base.queryParameters['screen'] ?? 'default';
    final data = switch (screen) {
      'empty' => null,
      'imperial' => const OnboardingData(
          goal: 'Lose Weight',
          experience: 'Beginner',
          workoutDays: 3,
          gender: 'Female',
          height: '5.9 ft',
          weight: '165 lbs',
        ),
      'advanced' => const OnboardingData(
          goal: 'Build Aesthetics',
          experience: 'God in Human Form',
          workoutDays: 6,
          gender: 'Other',
          height: '183 cm',
          weight: '84 kg',
        ),
      _ => const OnboardingData(
          goal: 'Build Muscle',
          experience: 'Experienced',
          workoutDays: 4,
          gender: 'Male',
          height: '178 cm',
          weight: '78 kg',
        ),
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: kBodyBg),
      builder: (context, child) => ColoredBox(
        color: kBodyBg,
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 390), child: child)),
      ),
      home: AdjustWorkoutPlanPage(
        load: () async => data,
        save: (_) async {},
        onContinue: () {},
      ),
    );
  }
}
