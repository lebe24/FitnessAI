import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design tokens shared by the plan-update screens. Same values as the rest of
// the app's dark theme.
const kProgBg = Color(0xFF0A0C12);
const kProgCard = Color(0xFF111318);
const kProgRaised = Color(0xFF161B26);
const kProgBorder = Color(0xFF1E2330);
const kProgLime = Color(0xFFCCFF00);
const kProgMuted = Color(0xFF8C909B);
const kProgGreen = Color(0xFF1ACA31);
const kProgAmber = Color(0xFFFFAA00);
const kProgBlue = Color(0xFF5B9DFF);

TextStyle progHeading(double size, {Color color = Colors.white}) =>
    GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w700, color: color, height: 1.2);

TextStyle progBody(double size,
        {Color color = Colors.white, FontWeight weight = FontWeight.w500, double? height}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: height);

/// Colour that stands for each kind of change, used on the pill and the arrow.
Color colorForKind(ChangeKind kind) => switch (kind) {
      ChangeKind.load => kProgLime,
      ChangeKind.reps => kProgGreen,
      ChangeKind.sets => kProgBlue,
      ChangeKind.deload => kProgAmber,
      ChangeKind.hold => kProgMuted,
    };

IconData iconForKind(ChangeKind kind) => switch (kind) {
      ChangeKind.load => Icons.trending_up_rounded,
      ChangeKind.reps => Icons.repeat_rounded,
      ChangeKind.sets => Icons.layers_rounded,
      ChangeKind.deload => Icons.battery_charging_full_rounded,
      ChangeKind.hold => Icons.pause_rounded,
    };

String labelForKind(ChangeKind kind) => switch (kind) {
      ChangeKind.load => 'Heavier',
      ChangeKind.reps => 'More reps',
      ChangeKind.sets => 'More volume',
      ChangeKind.deload => 'Recovery',
      ChangeKind.hold => 'Hold',
    };

/// The round back button used on every screen here.
class ProgBackButton extends StatelessWidget {
  const ProgBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kProgBorder),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
