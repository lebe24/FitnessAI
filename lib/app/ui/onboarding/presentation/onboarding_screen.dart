
import 'package:fitness/app/core/di.dart' as di;
import 'package:fitness/app/ui/auth/presentation/bloc/auth_bloc.dart';
import 'package:fitness/app/ui/auth/presentation/page/auth_page.dart';
import 'package:fitness/app/ui/onboarding/bloc/onboarding_bloc.dart';
import 'package:fitness/app/ui/onboarding/presentation/screens/dob.dart';
import 'package:fitness/app/ui/onboarding/presentation/screens/experience.dart';
import 'package:fitness/app/ui/onboarding/presentation/screens/gender.dart';
import 'package:fitness/app/ui/onboarding/presentation/screens/goal.dart';
import 'package:fitness/app/ui/onboarding/presentation/screens/heightAndweight.dart';
import 'package:fitness/app/ui/onboarding/presentation/screens/motivation_quote.dart';
import 'package:fitness/app/ui/onboarding/presentation/screens/summary.dart';
import 'package:fitness/app/ui/onboarding/presentation/screens/workoutdays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingBloc(),
      child: Builder(
        builder: (builderContext) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              if (didPop) return;
              
              final bloc = builderContext.read<OnboardingBloc>();
              final currentStep = bloc.state.step;
              
              // If we're at the first step (gender), allow normal system back (exit app)
              if (currentStep == OnboardingStep.gender) {
                // Allow pop to exit the onboarding screen
                if (builderContext.mounted) {
                  Navigator.of(builderContext).pop();
                }
              } else {
                // Otherwise, go back one step in onboarding
                bloc.add(PreviousStep());
              }
            },
            child: Scaffold(
              body: BlocBuilder<OnboardingBloc, OnboardingState>(
                builder: (context, state) {
                  switch (state.step) {
                    case OnboardingStep.workoutDays:
                      return WorkoutDaysStep();
                    case OnboardingStep.gender:
                      return GenderStep();
                    case OnboardingStep.goal:
                      return GoalStep();
                    case OnboardingStep.experience:
                      return ExperienceStep();
                    case OnboardingStep.heightAndWeight:
                      return HeightAndWeightStep();
                    case OnboardingStep.dob:
                      return DateOfBirthStep();
                    case OnboardingStep.signup:
                      return BlocProvider<AuthBloc>(
                        create: (_) => di.sl<AuthBloc>(),
                        child: const SignUp(),
                      );
                    case OnboardingStep.summary:
                      return SummaryStep();
                    case OnboardingStep.motivationQuote:
                      return MotivationQuote();
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
