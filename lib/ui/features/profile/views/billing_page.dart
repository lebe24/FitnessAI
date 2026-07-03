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

/// Billing/subscription overview. No payment processor is wired up yet —
/// this is the UI shell; "Upgrade" surfaces a "coming soon" message rather
/// than faking a purchase. Wire to RevenueCat/Stripe/in_app_purchase when
/// monetization is ready.
class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  bool _yearly = true;

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium billing isn\'t live yet — check back soon!')),
    );
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
                    Text('Free', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
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
              isCurrent: true,
              onTap: null,
            ).animate(delay: 120.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // ── Premium plan card ────────────────────────────────────
            _PlanCard(
              name: 'Premium',
              price: _yearly ? '\$79' : '\$8',
              priceSuffix: _yearly ? '.99/year' : '.99/month',
              description: 'Best for serious training — unlimited AI plans, coaching, and analysis.',
              features: _premiumFeatures,
              accent: _kLime,
              isCurrent: false,
              isHighlighted: true,
              onTap: _showComingSoon,
            ).animate(delay: 160.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 28),
            _SectionLabel(label: 'Payment Method', icon: Icons.credit_card_outlined),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _showComingSoon,
              child: Container(
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
                    child: Icon(Icons.add_card_rounded, color: _kBlue, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('No payment method on file',
                        style: GoogleFonts.inter(fontSize: 13, color: _kDim)),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.25), size: 20),
                ]),
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showComingSoon,
              child: Center(
                child: Text('Restore purchases',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _kDim)),
              ),
            ).animate(delay: 240.ms).fadeIn(duration: 300.ms),
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
