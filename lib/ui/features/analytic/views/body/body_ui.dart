import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';
import 'package:fitness/domain/body/muscle_focus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Tokens for the body-tracking cards. The surfaces match the rest of the dark
// UI; the status colours come from the Body Composition design.
const kBodyBg = Color(0xFF0A0C12);
const kBodyCard = Color(0xFF111318);
const kBodyRaised = Color(0xFF161B26);
const kBodyBorder = Color(0xFF1E2330);

/// An unselected filter chip.
const kBodyChip = Color(0xFF171A22);
const kBodyLime = Color(0xFFCCFF00);
const kBodyMuted = Color(0xFF8C909B);

/// Secondary text on a tinted card, where the usual grey loses contrast.
const kBodySoft = Color(0xFFC9CCD3);
const kBodyBlue = Color(0xFF6FA8FF);
const kBodyAmber = Color(0xFFFFAA00);
const kBodyGreen = Color(0xFF4DFF9E);
const kBodyRed = Color(0xFFFF4D4D);
const kBodyUntrained = Color(0xFF232837);

TextStyle bodyHeading(double size, {Color color = Colors.white}) =>
    GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w700, color: color, height: 1.2);

TextStyle bodyText(double size,
        {Color color = Colors.white, FontWeight weight = FontWeight.w500, double? height}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: height);

/// The colour of a muscle group on the development map and in its chips.
Color levelColor(MuscleLevel level) => switch (level) {
      MuscleLevel.strong => kBodyLime,
      MuscleLevel.average => kBodyBlue,
      MuscleLevel.focus => kBodyAmber,
      MuscleLevel.untrained => kBodyUntrained,
    };

String levelLabel(MuscleLevel level) => switch (level) {
      MuscleLevel.strong => 'Strong',
      MuscleLevel.average => 'Average',
      MuscleLevel.focus => 'Focus',
      MuscleLevel.untrained => 'Untrained',
    };

/// The 1–10 score colours the Body Composition screen uses.
Color scoreColor(int score) {
  if (score >= 8) return kBodyGreen;
  if (score >= 6) return kBodyLime;
  if (score >= 4) return kBodyAmber;
  return kBodyRed;
}

Color statusColor(ProgressStatus s) => switch (s) {
      ProgressStatus.onTrack => kBodyLime,
      ProgressStatus.ahead => kBodyGreen,
      ProgressStatus.behind => kBodyAmber,
      ProgressStatus.tooFast => kBodyRed,
      ProgressStatus.notEnoughData || ProgressStatus.noGoal => kBodyMuted,
    };

String statusLabel(ProgressStatus s) => switch (s) {
      ProgressStatus.onTrack => 'On track',
      ProgressStatus.ahead => 'Ahead',
      ProgressStatus.behind => 'Behind',
      ProgressStatus.tooFast => 'Too fast',
      ProgressStatus.notEnoughData => 'Gathering data',
      ProgressStatus.noGoal => 'No goal',
    };

/// A weight in the user's unit, or an en dash when there is none.
String weightText(double? kg, bool imperial) =>
    kg == null ? '–' : BodyUnits.weight(kg, imperial: imperial);

String signedWeight(double kg, bool imperial) {
  final v = imperial ? BodyUnits.kgToLb(kg) : kg;
  final s = v.abs().toStringAsFixed(1);
  final trimmed = s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  return '${v < 0 ? '−' : '+'}$trimmed ${imperial ? 'lb' : 'kg'}';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// The rounded dark card every section sits in.
class BodyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Gradient? gradient;

  const BodyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? kBodyCard : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor ?? kBodyBorder),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: box);
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: bodyHeading(16)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: bodyText(12, color: kBodyMuted, height: 1.4)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A small coloured label such as "On track" or "Focus".
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StatusPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(label, style: bodyText(11.5, color: color, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// A lime filled button, or an outlined one.
class BodyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final IconData? icon;
  final bool busy;
  const BodyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.icon,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.black : Colors.white;
    final child = busy
        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 17, color: fg), const SizedBox(width: 7)],
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(13.5, color: fg, weight: FontWeight.w700)),
              ),
            ],
          );
    return SizedBox(
      height: 44,
      child: filled
          ? FilledButton(
              onPressed: busy ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: kBodyLime,
                disabledBackgroundColor: kBodyLime.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: busy ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kBodyBorder),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: child,
            ),
    );
  }
}

/// A kg/lb or cm/in switch.
class UnitToggle extends StatelessWidget {
  final bool imperial;
  final String metric;
  final String imperialLabel;
  final ValueChanged<bool> onChanged;
  const UnitToggle({
    super.key,
    required this.imperial,
    required this.onChanged,
    this.metric = 'kg',
    this.imperialLabel = 'lb',
  });

  @override
  Widget build(BuildContext context) {
    Widget seg(String text, bool value) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: imperial == value ? kBodyLime : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(text,
                style: bodyText(11.5,
                    color: imperial == value ? Colors.black : kBodyMuted, weight: FontWeight.w700)),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: kBodyBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBodyBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg(metric, false), seg(imperialLabel, true)]),
    );
  }
}

/// The rounded bottom sheet frame used by every sheet here.
Future<T?> showBodySheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
        decoration: const BoxDecoration(
          color: kBodyCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: kBodyBorder)),
        ),
        child: SafeArea(top: false, child: builder(ctx)),
      ),
    ),
  );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 14),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

/// A text field in the dark style used on the sheets.
class BodyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? hint;
  final TextInputType keyboard;
  final String? error;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const BodyField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.hint,
    this.keyboard = const TextInputType.numberWithOptions(decimal: true),
    this.error,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      autofocus: autofocus,
      onChanged: onChanged,
      style: bodyText(15, weight: FontWeight.w600),
      cursorColor: kBodyLime,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        errorText: error,
        labelStyle: bodyText(13, color: kBodyMuted),
        hintStyle: bodyText(15, color: kBodyMuted.withValues(alpha: 0.6)),
        suffixStyle: bodyText(13, color: kBodyMuted),
        filled: true,
        fillColor: kBodyBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBodyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBodyLime),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBodyRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBodyRed),
        ),
      ),
    );
  }
}

/// Parses a number a person typed, accepting a comma as the decimal mark.
double? parseNumber(String text) => double.tryParse(text.trim().replaceAll(',', '.'));
