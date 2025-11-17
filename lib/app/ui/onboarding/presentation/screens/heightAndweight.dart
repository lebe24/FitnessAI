import 'package:fitness/app/ui/onboarding/bloc/onboarding_bloc.dart';
import 'package:fitness/app/ui/onboarding/presentation/share_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class HeightAndWeightStep extends StatefulWidget {
  const HeightAndWeightStep({super.key});

  @override
  State<HeightAndWeightStep> createState() => _HeightAndWeightStepState();
}

class _HeightAndWeightStepState extends State<HeightAndWeightStep> {
  bool _heightSelected = false;
  bool _weightSelected = false;

  @override
  Widget build(BuildContext context) {
    // Imperial height lists
    final feetList = List.generate(8, (i) => i + 2);
    final inchList = List.generate(12, (i) => i);
    
    // Metric height list (1.0m to 2.5m in 0.1 increments)
    final meterList = List.generate(16, (i) => 1.0 + (i * 0.1));
    
    // Weight lists
    final kgList = List.generate(100, (i) => i + 40);
    final lbsList = List.generate(200, (i) => i + 80);

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
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
                TextSpan(text: "Height &"),
                TextSpan(
                  text: " Weight",
                  style: TextStyle(
                    backgroundColor: Color(0xFFCCFF00),
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
          subtitle: "This data allows the AI to tailor your workout",
          children: [
            // Toggle Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Imperial',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16)
                  ),
                ),
                Switch(
                  value: state.isMetric,
                  onChanged: (val) {
                    context.read<OnboardingBloc>().add(ToggleUnitSystem(val));
                  },
                  activeThumbColor: const Color.fromARGB(255, 21, 21, 21),
                  inactiveTrackColor: Colors.white12,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Metric',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Height Picker
            Column(
              children: [
                const Text(
                  'Height',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: state.isMetric
                      ? // Metric: Single meter picker
                      CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem:
                              _getMeterIndex(state.selectedMeters, meterList),
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _heightSelected = true;
                          });
                          context.read<OnboardingBloc>().add(
                                SelectHeightMeters(meterList[index]),
                              );
                        },
                        children: meterList
                            .map(
                              (m) => Center(
                                child: Text(
                                  '${m.toStringAsFixed(1)} m',
                                  style: const TextStyle(
                                    // color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      )
                      : // Imperial: Feet and inches pickers
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Feet picker
                            Expanded(
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                  initialItem: _clampIndex(
                                      state.selectedFeet - 2,
                                      0,
                                      feetList.length - 1),
                                ),
                                itemExtent: 40,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    _heightSelected = true;
                                  });
                                  context.read<OnboardingBloc>().add(
                                        SelectHeightFt(
                                            feetList[index],
                                            state.selectedInches),
                                      );
                                },
                                children: feetList
                                    .map(
                                      (f) => Center(
                                        child: Text(
                                          '$f ft',
                                          style: const TextStyle(
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            // Inches picker
                            Expanded(
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                  initialItem: _clampIndex(
                                      state.selectedInches,
                                      0,
                                      inchList.length - 1),
                                ),
                                itemExtent: 40,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    _heightSelected = true;
                                  });
                                  context.read<OnboardingBloc>().add(
                                        SelectHeightFt(
                                            state.selectedFeet, index),
                                      );
                                },
                                children: inchList
                                    .map(
                                      (i) => Center(
                                        child: Text(
                                          '$i in',
                                          style: const TextStyle(
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Weight Picker
            Column(
              children: [
                const Text(
                  'Weight',
                  style: TextStyle(
                      fontSize: 20,
                       fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 180,
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: state.isMetric
                          ? _clampIndex(
                              state.selectedKg - 40, 0, kgList.length - 1)
                          : _clampIndex(
                              state.selectedLbs - 80, 0, lbsList.length - 1),
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _weightSelected = true;
                      });
                      if (state.isMetric) {
                        // Only update kg when metric is selected
                        context.read<OnboardingBloc>().add(
                              SelectWeightWt(kg: kgList[index]),
                            );
                      } else {
                        // Only update lbs when imperial is selected
                        context.read<OnboardingBloc>().add(
                              SelectWeightWt(lbs: lbsList[index]),
                            );
                      }
                    },
                    children: (state.isMetric ? kgList : lbsList)
                        .map(
                          (w) => Center(
                            child: Text(
                              '$w ${state.isMetric ? 'kg' : 'lbs'}',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
          onContinue: () {
            if (!_heightSelected || !_weightSelected) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Please select both your height and your weight.')),
              );
              return;
            }

            // Save height as string
            final heightString = state.isMetric
                ? '${state.selectedMeters.toStringAsFixed(1)} m'
                : '${state.selectedFeet} ft ${state.selectedInches} in';
            context.read<OnboardingBloc>().add(SelectHeight(heightString));

            // Save weight as string
            final weightString = state.isMetric
                ? '${state.selectedKg} kg'
                : '${state.selectedLbs} lbs';
            context.read<OnboardingBloc>().add(SelectWeight(weightString));

            // Move to next step
            context.read<OnboardingBloc>().add(NextStep());
          },
        );
      },
    );
  }

  // Helper method to clamp index to valid range
  int _clampIndex(int index, int min, int max) {
    if (index < min) return min;
    if (index > max) return max;
    return index;
  }

  // Helper method to find the closest meter index
  int _getMeterIndex(double meters, List<double> meterList) {
    int closestIndex = 0;
    double minDifference = double.infinity;
    for (int i = 0; i < meterList.length; i++) {
      final difference = (meters - meterList[i]).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestIndex = i;
      }
    }
    return closestIndex;
  }
}
