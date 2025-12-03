import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/ui/onboarding/bloc/onboarding_bloc.dart';
import 'package:fitness/app/ui/onboarding/presentation/share_screen.dart';
import 'package:fitness/app/ui/onboarding/utils/onboarding_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SummaryStep extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final data = context.watch<OnboardingBloc>().state.data;
    return BaseStepLayout(
      title: Text(
        "Your Summary",
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
      subtitle: "Here’s what you selected:",
      children: [
        Text("Workout Days: ${data.workoutDays ?? '-'}",
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text("Gender: ${data.gender ?? '-'}",
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text("Goal: ${data.goal ?? '-'}", style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text("Height: ${data.height ?? '-'}", 
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text("Weight: ${data.weight ?? '-'}", 
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text("Date of Birth: ${data.dob ?? '-'}", style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text("Experience: ${data.experience ?? '-'}", style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
      ],
      onContinue: () async {
        // Save onboarding data before navigating
        await OnboardingStorage.saveOnboardingData(data);
        if (context.mounted) {
          context.go('/analysis');
        }
      },
    );
  }
}