import 'package:fitness/app/core/common/widget/appWidget.dart';
import 'package:fitness/app/ui/onboarding/bloc/onboarding_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BaseStepLayout extends StatelessWidget {
  final Widget title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback onContinue;

   const BaseStepLayout({super.key, 
    required this.title,
    required this.subtitle,
    required this.children,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    // Basic layout similar to your screenshots: header, content, continue button
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            title,
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            // content area expands
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: children
                      .map((w) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: w,
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // progress-like bar placeholder (you can change visuals)
            SizedBox(
              height: 6,
              width: double.infinity,
              child: LinearProgressIndicator(
                value: progressForContext(context),
                backgroundColor: Colors.black12,
                color: Colors.lightGreen,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppWidgets.roundbtnText(
                onPressed: onContinue,
                text: "Continue",
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }


  double progressForContext(BuildContext context) {
    final step = context.read<OnboardingBloc>().state.step;
    switch (step) {
      case OnboardingStep.gender:
        return 0.05;
      case OnboardingStep.workoutDays:
        return 0.15;
      case OnboardingStep.goal:
        return 0.35;
      case OnboardingStep.experience:
        return 0.50;
      case OnboardingStep.heightAndWeight:
        return 0.65;
      case OnboardingStep.dob:
        return 0.80;
      case OnboardingStep.signup:
        return 0.95;
      case OnboardingStep.summary:
        return 1.0;
      case OnboardingStep.motivationQuote:
        return 1.0;
      }
  }
}

class OptionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Widget? child;
  final VoidCallback onTap;
  final bool isSelected;
  final bool disable;

  const OptionButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isSelected = false, this.child, required this.disable, 
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? Colors.greenAccent.shade700 : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: disable ? child : newMethod(color),
    );
  }

  Container newMethod(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? Colors.greenAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.white, fontSize: 15)),
          ],
        ],
      ),
    );
  }
}