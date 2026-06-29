import 'package:fitness/ui/core/di.dart' as di;
import 'package:fitness/ui/features/auth/view_models/auth_view_model.dart';
import 'package:fitness/ui/features/auth/views/auth_page.dart';
import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:fitness/ui/features/onboarding/views/decide.dart';
import 'package:fitness/ui/features/onboarding/views/dob.dart';
import 'package:fitness/ui/features/onboarding/views/experience.dart';
import 'package:fitness/ui/features/onboarding/views/gender.dart';
import 'package:fitness/ui/features/onboarding/views/goal.dart';
import 'package:fitness/ui/features/onboarding/views/height_and_weight.dart';
import 'package:fitness/ui/features/onboarding/views/motivation_quote.dart';
import 'package:fitness/ui/features/onboarding/views/summary.dart';
import 'package:fitness/ui/features/onboarding/views/workoutdays.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: const _OnboardingBody(),
    );
  }
}

class _OnboardingBody extends StatelessWidget {
  const _OnboardingBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<OnboardingViewModel>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (viewModel.step == OnboardingStep.gender) {
          Navigator.of(context).pop();
        } else {
          viewModel.previousStep();
        }
      },
      child: Scaffold(
        body: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            switch (viewModel.step) {
              case OnboardingStep.workoutDays:
                return const WorkoutDaysStep();
              case OnboardingStep.gender:
                return const GenderStep();
              case OnboardingStep.goal:
                return const GoalStep();
              case OnboardingStep.experience:
                return const ExperienceStep();
              case OnboardingStep.heightAndWeight:
                return const HeightAndWeightStep();
              case OnboardingStep.dob:
                return const DateOfBirthStep();
              case OnboardingStep.signup:
                return ChangeNotifierProvider(
                  create: (_) => di.sl<AuthViewModel>(),
                  child: const SignUp(),
                );
              case OnboardingStep.summary:
                return const SummaryStep();
              case OnboardingStep.decide:
                return const DecideStep();
              case OnboardingStep.motivationQuote:
                return const MotivationQuote();
            }
          },
        ),
      ),
    );
  }
}
