import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/onboarding/bloc/onboarding_bloc.dart';
import 'package:fitness/app/ui/onboarding/presentation/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ExperienceStep extends StatelessWidget {
  const ExperienceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingBloc>().state;
    final selectedExperience = state.data.experience;

    return BaseStepLayout(
      title: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          children: const [
            TextSpan(text: "What's Your"),
            TextSpan(
              text: "Experience",
              style: TextStyle(
                backgroundColor: Color(0xFFCCFF00),
                color: Colors.black,
              ),
            ),
            TextSpan(text: "\nLevel?"),
          ]
        )
      ),
      subtitle: "This helps us tailor the perfect workout plan for you",
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OptionButton(
            disable: false,
            label: "Beginner",
            subtitle: "Just starting out",
            isSelected: selectedExperience == "Beginner",
            onTap: () {
              context.read<OnboardingBloc>().add(SelectExperience("Beginner"));
            },
          ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OptionButton(
            disable: false,
            label: "Experienced",
            subtitle: "Been at it for a while",
            isSelected: selectedExperience == "Experienced",
            onTap: () {
              context.read<OnboardingBloc>().add(SelectExperience("Experienced"));
            },
          ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OptionButton(
            disable: false,
            label: "Freak of Nature",
            subtitle: "Elite level athlete",
            isSelected: selectedExperience == "Freak of Nature",
            onTap: () {
              context.read<OnboardingBloc>().add(SelectExperience("Freak of Nature"));
            },
          ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OptionButton(
            disable: false,
            label: "God in Human Form",
            subtitle: "Legendary status",
            isSelected: selectedExperience == "God in Human Form",
            onTap: () {
              context.read<OnboardingBloc>().add(SelectExperience("God in Human Form"));
            },
          ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
        ),
      ],
      onContinue: () {
        final experience = context.read<OnboardingBloc>().state.data.experience;
        if (experience == null || experience.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select your experience level before continuing.')),
          );
          return;
        }
        context.read<OnboardingBloc>().add(NextStep());
      },
    );
  }
}


