import 'package:fitness/app/ui/onboarding/bloc/onboarding_bloc.dart';
import 'package:fitness/app/ui/onboarding/presentation/share_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class DateOfBirthStep extends StatefulWidget {
  const DateOfBirthStep({Key? key}) : super(key: key);

  @override
  _DateOfBirthStepState createState() => _DateOfBirthStepState();
}

class _DateOfBirthStepState extends State<DateOfBirthStep> {
  int selectedMonth = 0;
  int selectedDay = 0;
  int selectedYear = 2000;

  final months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final days = List.generate(31, (index) => index + 1);
  final years = List.generate(100, (index) => 2030 - index); // 1925 - 2025

  @override
  Widget build(BuildContext context) {
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
            TextSpan(text: "Date Of"),
              TextSpan(
                text: " Birth",
                style: TextStyle(
                  backgroundColor: Color(0xFFCCFF00),
                  color: Colors.black,
                ),
              ),
          ]
        )
      ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
      subtitle: "This data allows the AI to tailor your workout",
      onContinue: () {
        // Require the user to scroll/pick at least one value explicitly
        // by checking if selections differ from initial defaults.
        final hasInteracted =
            selectedMonth != 0 || selectedDay != 0 || selectedYear != 2000;

        if (!hasInteracted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select your date of birth.')),
          );
          return;
        }

        final day = days[selectedDay];
        final month = selectedMonth + 1; // months list is 0-based
        final year = selectedYear;

        final dob = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

        context.read<OnboardingBloc>().add(SelectDob(dob));
        context.read<OnboardingBloc>().add(NextStep());
      },
      children:  [ 
        Center(
          child: SizedBox(
            height: 500,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Month Picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: selectedMonth),
                    itemExtent: 48,
                    onSelectedItemChanged: (index) {
                      setState(() => selectedMonth = index);
                    },
                    children: months
                        .map((month) => Center(
                              child: Text(
                                month,
                                style: const TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                // Day Picker
                Expanded(
                  child: CupertinoPicker(
                    // selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                    //   background: CupertinoColors.activeGreen.withOpacity(0.5),
                    // ),
                    scrollController: FixedExtentScrollController(initialItem: selectedDay),
                    itemExtent: 48,
                    onSelectedItemChanged: (index) {
                      setState(() => selectedDay = index);
                    },
                    children: days
                        .map((day) => Center(
                              child: Text(
                                day.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  
                                  fontSize: 18,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
            
                // Year Picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                        initialItem: years.indexOf(selectedYear)),
                    itemExtent: 48,
                    onSelectedItemChanged: (index) {
                      setState(() => selectedYear = years[index]);
                    },
                    children: years
                        .map((year) => Center(
                              child: Text(
                                year.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),]
    );
  }
}
