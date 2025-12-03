import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/onboarding/bloc/onboarding_bloc.dart';
import 'package:fitness/app/ui/onboarding/presentation/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class GenderStep extends StatelessWidget {
  const GenderStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingBloc>().state;
    final selectedGender = state.data.gender;

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
            TextSpan(text: "Choose"),
              TextSpan(
                text: "Your",
                style: TextStyle(
                  backgroundColor: Color(0xFFCCFF00),
                  color: Colors.black,
                ),
              ),
            TextSpan(text: "\nGender"),
          ]
        )
      ),
      subtitle: "This data allows the AI to tailor your workout",
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OptionButton(
            disable: true,
            label: "Male", subtitle: "", isSelected: selectedGender == "Male", onTap: () {
            context.read<OnboardingBloc>().add(SelectGender("Male"));
          },
            child: Column(
              children: [
                Icon(Icons.male, size: 80,color: selectedGender == "Male" ?  AppPallete.accent1 : Colors.black,).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
                Text("Male",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: selectedGender == "Male" ?  AppPallete.accent1 : Colors.black,
                  ),
                ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0)
              ],
            ),),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OptionButton(
            disable: true,
            label: "Female", subtitle: "", isSelected: selectedGender == "Female", onTap: () {
            context.read<OnboardingBloc>().add(SelectGender("Female"));
          },child: Column(
            children: [
              Icon(Icons.female, size: 80,color: selectedGender == "Female" ?  AppPallete.accent1 : Colors.black).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
              Text("Female",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: selectedGender == "Female" ?  AppPallete.accent1 : Colors.black,
                  ),
              )
            ],
          )),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OptionButton(
            disable: true,
            label: "Others", subtitle: "", isSelected: selectedGender == "Others", onTap: () {
            context.read<OnboardingBloc>().add(SelectGender("Others"));
          },child: Column(
            children: [
              SizedBox(
                height: 100,
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: 5,
                      child: Icon(Icons.female, size: 80,color: selectedGender == "Others" ?  AppPallete.accent1 : Colors.black).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0)),
                    Icon(Icons.male, size: 80,color: selectedGender == "Others" ?  AppPallete.accent1 : Colors.black).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
                
                  ],
                ),
              ),
              Text("Prefer Not To Say",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: selectedGender == "Prefer Not To Say" ?  AppPallete.accent1 : Colors.black,
                  ),
              )
            ],
          )),
        ),
      ],
      onContinue: () {
        final gender = context.read<OnboardingBloc>().state.data.gender;
        if (gender == null || gender.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a gender before continuing.')),
          );
          return;
        }
        context.read<OnboardingBloc>().add(NextStep());
      },
    );
  }
}
