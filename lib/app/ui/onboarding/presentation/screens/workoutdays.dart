import 'package:fitness/app/ui/onboarding/bloc/onboarding_bloc.dart';
import 'package:fitness/app/ui/onboarding/presentation/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkoutDaysStep extends StatelessWidget {
  const WorkoutDaysStep({super.key});

   @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingBloc>().state;
    final selectedWorkout = state.data.workoutDays;


    return BaseStepLayout(
      // title: "How Many Days Do You Workout Per Week",
      title: RichText(
        textAlign: TextAlign.center,
        text:TextSpan(
          style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
          ),
          children:const [
            TextSpan(text: "How Many Days Do You"),
              TextSpan(
                text: "Workout",
                style: TextStyle(
                  backgroundColor: Color(0xFFCCFF00),
                  color: Colors.black,
                ),
              ),
            TextSpan(text: "\nPer Week"),
          ]
        )
      ),
      subtitle: "This data allows the AI to tailor your workout",
      children: [
        OptionButton(
          disable: false,
          label: "1 - 2", subtitle: "Hobbyist", isSelected: selectedWorkout == 2, onTap: () {
          context.read<OnboardingBloc>().add(SelectWorkoutDays(2));
        }).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
        OptionButton(
          disable: false,
          label: "3 - 4", subtitle: "Fitness Guru", isSelected: selectedWorkout == 4, onTap: () {
          context.read<OnboardingBloc>().add(SelectWorkoutDays(4));
        }).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
        OptionButton(
          disable: false,
          label: "6+", subtitle: "Athlete/Gym Rat",isSelected: selectedWorkout == 6, onTap: () {
          context.read<OnboardingBloc>().add(SelectWorkoutDays(6));
        }).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
      ],
      onContinue: () {
        if (selectedWorkout == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select how many days you work out per week.')),
          );
          return;
        }
        context.read<OnboardingBloc>().add(NextStep());
      },
    );
  }
}
