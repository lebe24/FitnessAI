import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/billing/paywall_service.dart';
import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kLime = Color(0xFFCCFF00);
const _kCard = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kDim = Color(0x99FFFFFF);

/// Offered once, immediately before the first plan is generated.
///
/// Placed here on purpose. The user has just answered everything about
/// themselves and is seconds from seeing what the app built for them — the
/// moment of highest intent in the whole flow, and the last one before they
/// have the thing they came for.
///
/// It is skippable. Blocking plan generation behind payment would mean a user
/// who declines never sees the product work, and Apple takes a dim view of an
/// onboarding that cannot be completed without buying.
class TrialOfferSheet extends StatefulWidget {
  const TrialOfferSheet({super.key});

  /// Shows the offer and resolves once the user has chosen.
  ///
  /// Returns true when they came away entitled. The caller continues into plan
  /// generation either way — the return value is only worth acting on if you
  /// want to say something different afterwards.
  static Future<bool> show(BuildContext context) async {
    // Nothing to sell to someone who already has it: a user reinstalling, or
    // returning after a lapse they have already fixed, must not be pitched.
    if (!sl<AccessPolicy>().isFree) return true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TrialOfferSheet(),
    );
    return result ?? false;
  }

  @override
  State<TrialOfferSheet> createState() => _TrialOfferSheetState();
}

class _TrialOfferSheetState extends State<TrialOfferSheet> {
  bool _busy = false;

  /// Null until the eligibility check answers. Until then the sheet says
  /// nothing about a trial rather than promising one it may have to retract.
  bool? _eligible;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    final eligible = await sl<SubscriptionService>().isEligibleForTrial();
    if (mounted) setState(() => _eligible = eligible);
  }

  /// Read from the store, never hardcoded. If App Store Connect has no
  /// introductory offer configured, this is null and the sheet stops
  /// mentioning a trial entirely rather than promising one Apple will not
  /// honour — which is what a purchase that charges immediately looks like
  /// to a user who was told it was free.
  ///
  /// Suppressed once we know this Apple Account has already used its
  /// introductory offer — that is the "trial is over, show the paywall"
  /// case. The sheet then sells the subscription plainly.
  TrialOffer? get _trial =>
      _eligible == false ? null : sl<SubscriptionService>().trialOffer();

  static const _perks = [
    ('Nutrition scanner', 'Photograph a meal for instant macros'),
    ('Body composition', 'Track what is actually changing'),
    ('Your AI coach', 'Ask anything, any time'),
    ('Equipment scan', 'Point at a machine, get exercises'),
    ('Video tutorials', 'See every movement before you lift'),
    ('Daily motivation', 'Written from your own training'),
  ];

  Future<void> _start() async {
    setState(() => _busy = true);

    final subs = sl<SubscriptionService>();
    final package = subs.defaultPackage;

    // Buy the package directly rather than opening the paywall.
    //
    // The paywall is a browse-and-choose screen: it reads as "pick a plan and
    // pay", which is the wrong frame for someone who tapped "start my free
    // trial". Purchasing straight away puts Apple's own sheet in front of
    // them, and that sheet states the offer in Apple's words — "7 days free,
    // then …" — which is both clearer and harder to dispute than anything we
    // could write. The paywall is what they meet later, once the trial is
    // spent and a gated feature is tapped.
    if (package != null) {
      final result = await subs.purchase(package);
      if (!mounted) return;
      setState(() => _busy = false);

      if (result.shouldShowMessage && result.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message!,
              style: GoogleFonts.inter(fontSize: 13)),
          behavior: SnackBarBehavior.floating,
        ));
      }
      // Cancelling is a choice, not a failure — close either way and let
      // onboarding continue.
      Navigator.of(context).pop(result.isSuccess);
      return;
    }

    // No package loaded (offerings unavailable). Fall back to the paywall,
    // which has its own handling for that state.
    final purchased = await sl<PaywallService>().present();
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(purchased);
  }

  @override
  Widget build(BuildContext context) {
    final trial = _trial;
    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Your plan is ready to build',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                trial != null
                    ? 'Try everything free for ${trial.phrase}. Cancel any time before it ends and you will not be charged.'
                    : 'Unlock everything BeFit can do. Cancel any time from your Apple Account settings.',
                style: GoogleFonts.inter(
                    fontSize: 13, height: 1.5, color: _kDim),
              ),
              const SizedBox(height: 18),

              ..._perks.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.check_rounded,
                              size: 15, color: _kLime),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.$1,
                                  style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                              Text(p.$2,
                                  style: GoogleFonts.inter(
                                      fontSize: 11.5, color: _kDim)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 10),
              GestureDetector(
                onTap: _busy ? null : _start,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _busy ? Colors.white.withValues(alpha: 0.06) : _kLime,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kLime),
                          )
                        : Text(
                            trial != null
                                ? 'Start my ${trial.label} free trial'
                                : 'Unlock everything',
                            style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.black)),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Always available. An onboarding that cannot be finished
              // without paying is both a bad experience and a review risk.
              Center(
                child: TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                  child: Text('Maybe later',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white54)),
                ),
              ),

              Center(
                child: Text(
                  'Renews automatically after the trial. Manage or cancel in your Apple Account settings.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 10.5,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.35)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
