import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

const _kLime = Color(0xFFCCFF00);
const _kCard = Color(0xFF111318);
const _kDimWhite = Color(0x80FFFFFF);

/// Tells the user their free trial is about to become a paid subscription.
///
/// Shown once per trial, two days out. The point is that nobody is surprised
/// by the charge: it names the day, the amount where we know it, and the fact
/// that cancelling has to happen at least 24 hours before — which is Apple's
/// rule, not ours, and the detail people miss.
class TrialEndingDialog extends StatelessWidget {
  final int daysLeft;
  final DateTime endsAt;

  /// Localised price, or null when offerings have not loaded. The sentence
  /// reads correctly either way rather than showing an empty gap.
  final String? price;

  final VoidCallback onManage;

  const TrialEndingDialog({
    super.key,
    required this.daysLeft,
    required this.endsAt,
    required this.onManage,
    this.price,
  });

  static Future<void> show(
    BuildContext context, {
    required int daysLeft,
    required DateTime endsAt,
    required VoidCallback onManage,
    String? price,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => TrialEndingDialog(
        daysLeft: daysLeft,
        endsAt: endsAt,
        price: price,
        onManage: onManage,
      ),
    );
  }

  String get _when => switch (daysLeft) {
        <= 0 => 'ends today',
        1 => 'ends tomorrow',
        _ => 'ends in $daysLeft days',
      };

  String get _body {
    final date = DateFormat('EEEE d MMMM').format(endsAt);
    final amount = price == null ? 'your subscription starts' : 'you will be charged $price';
    return 'On $date $amount and BeFit AI Pro continues. '
        'To avoid it, cancel at least 24 hours before that — in your Apple '
        'Account settings.';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kLime.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: _kLime.withValues(alpha: 0.12),
              blurRadius: 34,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DialogHeader(),
            const SizedBox(height: 16),
            Text(
              'Your free trial $_when',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _body,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.55,
                color: _kDimWhite,
              ),
            ),
            const SizedBox(height: 20),
            _DialogActions(
              onManage: () {
                Navigator.of(context).pop();
                onManage();
              },
              onDismiss: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _kLime.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.timer_outlined, color: _kLime, size: 19),
        ),
        const SizedBox(width: 12),
        Text(
          'TRIAL ENDING',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _kLime,
          ),
        ),
      ],
    );
  }
}

class _DialogActions extends StatelessWidget {
  final VoidCallback onManage;
  final VoidCallback onDismiss;

  const _DialogActions({required this.onManage, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Text(
                'Got it',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onManage,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _kLime,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Manage plan',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
