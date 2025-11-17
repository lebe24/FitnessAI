import 'package:fitness/app/ui/onboarding/bloc/onboarding_bloc.dart';
import 'package:fitness/app/ui/onboarding/presentation/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class GoalStep extends StatelessWidget {
  const GoalStep({super.key});


  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingBloc>().state;
    final selectedGoal = state.data.goal;

    return BaseStepLayout(
      title: RichText(
        textAlign: TextAlign.center,
        text:TextSpan(
          style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
          ),
          children:const [
            TextSpan(text: "What Is Your"),
              TextSpan(
                text: " Goal",
                style: TextStyle(
                  backgroundColor: Color(0xFFCCFF00),
                  color: Colors.black,
                ),
              ),
          ]
        )
      ),
      subtitle: "This data allows the AI to tailor your workout",
      children: [
        OptionButton(
          disable: false,
          label: "Lose Weight",
          subtitle: "",
          isSelected: selectedGoal == "Lose Weight",
          onTap: () {
            context.read<OnboardingBloc>().add(SelectGoal("Lose Weight"));
          },
        ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
        OptionButton(
          disable: false,
          label: "Maintain",
          subtitle: "",
          isSelected: selectedGoal == "Maintain",
          onTap: () {
            context.read<OnboardingBloc>().add(SelectGoal("Maintain"));
          },
        ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
        OptionButton(
          disable: false,
          label: "Gain Weight",
          subtitle: "",
          isSelected: selectedGoal == "Gain Weight",
          onTap: () {
            context.read<OnboardingBloc>().add(SelectGoal("Gain Weight"));
          },
        ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),

        // Custom goal input
        TextFormField(
          initialValue: selectedGoal != "Lose Weight" &&
                  selectedGoal != "Maintain" &&
                  selectedGoal != "Gain Weight"
              ? selectedGoal
              : '',
          decoration: InputDecoration(
            labelText: "Did not find your goal? Enter it here",
            hintText: "e.g. Build muscle, get toned…",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            context.read<OnboardingBloc>().add(SelectGoal(value));
          },
        ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
      ],
      onContinue: () {
        final goal = context.read<OnboardingBloc>().state.data.goal;
        if (goal == null || goal.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select or enter a goal before continuing.')),
          );
          return;
        }
        context.read<OnboardingBloc>().add(NextStep());
      },
    );
  }
}