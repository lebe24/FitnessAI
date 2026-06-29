import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:fitness/ui/features/onboarding/views/share_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _lime = Color(0xFFCCFF00);

class DateOfBirthStep extends StatefulWidget {
  const DateOfBirthStep({super.key});

  @override
  State<DateOfBirthStep> createState() => _DateOfBirthStepState();
}

class _DateOfBirthStepState extends State<DateOfBirthStep> {
  int _month = 0;
  int _day = 0;
  int _year = 2000;
  bool _interacted = false;

  final _months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final _days = List.generate(31, (i) => i + 1);
  final _years = List.generate(100, (i) => 2025 - i);

  String get _preview {
    if (!_interacted) return '—';
    final m = _months[_month];
    final d = _days[_day].toString().padLeft(2, '0');
    return '$m $d, $_year';
  }

  @override
  Widget build(BuildContext context) {
    return BaseStepLayout(
      title: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
          children: const [
            TextSpan(text: 'Date Of '),
            TextSpan(text: 'Birth', style: TextStyle(backgroundColor: _lime, color: Colors.black)),
          ],
        ),
      ).animate().fadeIn(duration: 900.ms).slideY(begin: 0.2, end: 0),
      subtitle: 'Used to calculate age-adjusted training zones',
      children: [
        // Live preview pill
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: _interacted ? Colors.black : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: _interacted ? _lime : Colors.transparent, width: 2),
          ),
          child: Text(
            _preview,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _interacted ? _lime : Colors.black38,
            ),
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
        const SizedBox(height: 8),
        // Picker card
        Container(
          height: 220,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(children: [
            Expanded(child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: _month),
              itemExtent: 44,
              onSelectedItemChanged: (i) => setState(() { _month = i; _interacted = true; }),
              children: _months.map((m) => Center(
                child: Text(m, style: GoogleFonts.poppins(fontSize: 15)))).toList(),
            )),
            Expanded(child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: _day),
              itemExtent: 44,
              onSelectedItemChanged: (i) => setState(() { _day = i; _interacted = true; }),
              children: _days.map((d) => Center(
                child: Text(d.toString().padLeft(2, '0'), style: GoogleFonts.poppins(fontSize: 15)))).toList(),
            )),
            Expanded(child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: _years.indexOf(_year)),
              itemExtent: 44,
              onSelectedItemChanged: (i) => setState(() { _year = _years[i]; _interacted = true; }),
              children: _years.map((y) => Center(
                child: Text('$y', style: GoogleFonts.poppins(fontSize: 15)))).toList(),
            )),
          ]),
        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
      ],
      onContinue: () {
        if (!_interacted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select your date of birth.')),
          );
          return;
        }
        final dob =
            '$_year-${(_month + 1).toString().padLeft(2, '0')}-${_days[_day].toString().padLeft(2, '0')}';
        context.read<OnboardingViewModel>().selectDob(dob);
        context.read<OnboardingViewModel>().nextStep();
      },
    );
  }
}
