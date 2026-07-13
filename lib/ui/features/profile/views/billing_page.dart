import 'package:fitness/data/services/billing/billing_remote_service.dart';
import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/profile/views/legal_document_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens (matches profile_page.dart / BeFit dark theme) ───────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kBlue   = Color(0xFF4D9EFF);
const _kDim    = Color(0x80FFFFFF);

const _freeFeatures = [
  'AI workout plan generation (1 per month)',
  'Body composition photo analysis',
  'Basic progress tracking',
];

const _premiumFeatures = [
  'Unlimited AI workout plan generation',
  'Unlimited body composition analysis',
  'Personalised AI coach chat',
  'Nutrition photo analysis',
  'Priority support response',
  'Early access to new features',
];

/// Billing/subscription overview, backed by RevenueCat (Apple IAP).
/// When RevenueCat isn't configured (no API key in .env) the page degrades
/// to the pre-billing "coming soon" behaviour instead of crashing.
class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  bool _yearly = true;
  bool _busy = false;

  final _subs = sl<SubscriptionService>();
  final _billing = sl<BillingRemoteService>();
  UserSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subs.addListener(_onSubsChanged);
    final userId = sl<GetCurrentUser>()()?.id;
    _subs.init(userId);
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final sub = await _billing.getSubscription();
    if (mounted) setState(() => _subscription = sub);
  }

  @override
  void dispose() {
    _subs.removeListener(_onSubsChanged);
    super.dispose();
  }

  void _onSubsChanged() {
    if (mounted) setState(() {});
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showComingSoon() {
    _snack('Premium billing isn\'t live yet — check back soon!');
  }

  Future<void> _purchase() async {
    if (!_subs.isConfigured) {
      _showComingSoon();
      return;
    }
    final package = _yearly ? _subs.yearly : _subs.monthly;
    if (package == null) {
      _snack('Plans are still loading — try again in a moment.');
      _subs.refresh();
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await _subs.purchase(package);
      if (ok && mounted) {
        _snack('Welcome to BeFit Premium! 🎉');
        // The webhook writes the subscription row server-side; give it a
        // moment before refreshing the details card.
        Future.delayed(const Duration(seconds: 3), _loadSubscription);
      }
    } catch (_) {
      if (mounted) _snack('Purchase failed — you have not been charged.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (!_subs.isConfigured) {
      _showComingSoon();
      return;
    }
    setState(() => _busy = true);
    final ok = await _subs.restore();
    if (mounted) {
      setState(() => _busy = false);
      _snack(ok ? 'Premium restored.' : 'No previous purchases found.');
    }
  }

  /// Localized store price when offerings are loaded; fallback to the
  /// designed placeholder strings otherwise.
  (String, String) _premiumPrice() {
    final package = _yearly ? _subs.yearly : _subs.monthly;
    final price = package?.storeProduct.priceString;
    if (price != null) return (price, _yearly ? '/year' : '/month');
    return (_yearly ? '\$79' : '\$8', _yearly ? '.99/year' : '.99/month');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Billing',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          physics: const BouncingScrollPhysics(),
          children: [
            // ── Current plan card ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _kBorder),
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CURRENT PLAN',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _kDim, letterSpacing: 0.8)),
                    const SizedBox(height: 3),
                    Text(_subs.isPremium ? 'Premium' : 'Free',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800,
                            color: _subs.isPremium ? _kLime : Colors.white)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Active', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _kDim)),
                ),
              ]),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOut),

            // ── Subscription details (from user_subscriptions via backend) ──
            if (_subscription != null) ...[
              const SizedBox(height: 14),
              _SubscriptionDetailsCard(subscription: _subscription!)
                  .animate(delay: 60.ms)
                  .fadeIn(duration: 300.ms),
            ],

            const SizedBox(height: 28),
            _SectionLabel(label: 'Plans', icon: Icons.stacked_bar_chart_rounded),
            const SizedBox(height: 12),

            // ── Billing cycle toggle ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Row(children: [
                Expanded(child: _CycleTab(label: 'Monthly', isSelected: !_yearly, onTap: () => setState(() => _yearly = false))),
                Expanded(child: _CycleTab(label: 'Yearly · Save 20%', isSelected: _yearly, onTap: () => setState(() => _yearly = true))),
              ]),
            ).animate(delay: 80.ms).fadeIn(duration: 280.ms),

            const SizedBox(height: 16),

            // ── Free plan card ───────────────────────────────────────
            _PlanCard(
              name: 'Free',
              price: '\$0',
              priceSuffix: '/forever',
              description: 'Everything you need to start your fitness journey at no cost.',
              features: _freeFeatures,
              accent: _kDim,
              isCurrent: !_subs.isPremium,
              onTap: null,
            ).animate(delay: 120.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // ── Premium plan card ────────────────────────────────────
            Builder(builder: (_) {
              final (price, suffix) = _premiumPrice();
              return _PlanCard(
                name: 'Premium',
                price: price,
                priceSuffix: suffix,
                description: 'Best for serious training — unlimited AI plans, coaching, and analysis.',
                features: _premiumFeatures,
                accent: _kLime,
                isCurrent: _subs.isPremium,
                isHighlighted: true,
                onTap: _busy ? null : _purchase,
              );
            }).animate(delay: 160.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 28),
            _SectionLabel(label: 'Billing', icon: Icons.credit_card_outlined),
            const SizedBox(height: 12),

            // Payment is handled by Apple — no card entry in-app.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorder),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: _kBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
                  child: Icon(Icons.apple_rounded, color: _kBlue, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Billed through your Apple ID. Manage or cancel any time in Settings → Apple ID → Subscriptions.',
                      style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: _kDim)),
                ),
              ]),
            ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 16),
            GestureDetector(
              onTap: _busy ? null : _restore,
              child: Center(
                child: Text('Restore purchases',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _kDim)),
              ),
            ).animate(delay: 240.ms).fadeIn(duration: 300.ms),

            // ── Legal (required on any paywall by App Review) ─────────
            const SizedBox(height: 20),
            Text(
              'Subscriptions renew automatically unless cancelled at least 24 hours '
              'before the end of the current period. Payment is charged to your '
              'Apple ID account at confirmation of purchase.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 10, height: 1.5, color: Colors.white.withValues(alpha: 0.35)),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TermsAndConditionsPage())),
                child: Text('Terms of Use',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _kDim,
                        decoration: TextDecoration.underline, decorationColor: _kDim)),
              ),
              Text('  ·  ', style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyPage())),
                child: Text('Privacy Policy',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _kDim,
                        decoration: TextDecoration.underline, decorationColor: _kDim)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 15, color: _kDim),
      const SizedBox(width: 6),
      Text(label.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _kDim, letterSpacing: 0.8)),
    ]);
  }
}

// ── Billing cycle tab ──────────────────────────────────────────────────────────────

class _CycleTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _CycleTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kLime : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: isSelected ? Colors.black : _kDim)),
        ),
      ),
    );
  }
}

// ── Plan card ──────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String priceSuffix;
  final String description;
  final List<String> features;
  final Color accent;
  final bool isCurrent;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.priceSuffix,
    required this.description,
    required this.features,
    required this.accent,
    required this.isCurrent,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isHighlighted ? _kLime.withValues(alpha: 0.35) : _kBorder,
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: isHighlighted
            ? [BoxShadow(color: _kLime.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header zone (gradient for the highlighted plan) ──────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            gradient: isHighlighted
                ? const LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Color(0x00CCFF00),
                      Color(0x1FF66DA9),
                      Color(0x33BB3FDD),
                    ],
                  )
                : null,
            color: isHighlighted ? null : Colors.white.withValues(alpha: 0.02),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              if (isHighlighted) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _kLime, borderRadius: BorderRadius.circular(20)),
                  child: Text('BEST VALUE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ],
            ]),
            const SizedBox(height: 14),
            // Big price with small suffix, baseline-aligned like the template
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(price, style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 2),
                child: Text(priceSuffix, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kDim)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(description, style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 18),
            // Full-width pill CTA
            if (isCurrent)
              _PillButton(label: 'Current Plan', filled: false, onTap: null)
            else
              _PillButton(label: 'Start Free', filled: true, onTap: onTap),
          ]),
        ),
        // ── Features zone ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (int i = 0; i < features.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == features.length - 1 ? 0 : 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.check_circle_outline_rounded, size: 19, color: accent),
                  const SizedBox(width: 11),
                  Expanded(child: Text(features[i], style: GoogleFonts.inter(fontSize: 13, height: 1.35, color: Colors.white.withValues(alpha: 0.9)))),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ── Pill CTA button ──────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback? onTap;
  const _PillButton({required this.label, required this.filled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: filled ? Colors.black : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: filled ? null : Border.all(color: _kBorder),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: filled ? Colors.white : _kDim)),
        ),
      ),
    );
  }
}

// ── Subscription details card ─────────────────────────────────────────────────

class _SubscriptionDetailsCard extends StatelessWidget {
  final UserSubscription subscription;
  const _SubscriptionDetailsCard({required this.subscription});

  static String _date(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final s = subscription;
    final isCancelled = s.status == 'cancelled';
    final isExpired = s.status == 'expired';
    final expiryLabel = isExpired
        ? 'Expired'
        : isCancelled
            ? 'Ends'
            : 'Renews';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('SUBSCRIPTION',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _kDim, letterSpacing: 0.8)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isExpired
                  ? Colors.redAccent.withValues(alpha: 0.12)
                  : isCancelled
                      ? Colors.orangeAccent.withValues(alpha: 0.12)
                      : _kLime.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              s.status.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  color: isExpired
                      ? Colors.redAccent
                      : isCancelled
                          ? Colors.orangeAccent
                          : _kLime),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _DetailRow(label: 'Plan', value: s.planLabel),
        _DetailRow(label: 'Subscribed', value: _date(s.subscribedAt)),
        _DetailRow(label: expiryLabel, value: _date(s.expiresAt)),
        if (s.amountLabel.isNotEmpty) _DetailRow(label: 'Amount paid', value: s.amountLabel),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: _kDim)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
      ]),
    );
  }
}
