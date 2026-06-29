import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens (matches profile_page.dart / BeFit dark theme) ───────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kDim    = Color(0x80FFFFFF);

class LegalSection {
  final String heading;
  final String body;
  const LegalSection({required this.heading, required this.body});
}

/// Shared scaffold for static legal documents (Terms, Privacy Policy).
/// Renders a title, a "last updated" pill, and a list of heading/body
/// sections in the app's dark/lime design language.
class LegalDocumentPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String lastUpdated;
  final List<LegalSection> sections;

  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.icon,
    required this.lastUpdated,
    required this.sections,
  });

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
        title: Text(title,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: _kLime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kLime.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: _kLime, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Last updated $lastUpdated',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _kDim)),
                  ),
                ]),
              ),
            ]).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            ...sections.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 3, height: 14, decoration: BoxDecoration(
                          color: _kLime, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.heading,
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text(s.body,
                        style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: _kDim)),
                  ]),
                ),
              ).animate(delay: Duration(milliseconds: 60 + i * 40))
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.04, end: 0, curve: Curves.easeOut);
            }),
          ],
        ),
      ),
    );
  }
}

// ── Terms and Conditions ──────────────────────────────────────────────────────────

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentPage(
      title: 'Terms and Conditions',
      icon: Icons.description_outlined,
      lastUpdated: 'June 2026',
      sections: const [
        LegalSection(
          heading: '1. Acceptance of Terms',
          body: 'By creating an account or using BeFit AI, you agree to be bound by these '
              'Terms and Conditions. If you do not agree, please do not use the app.',
        ),
        LegalSection(
          heading: '2. AI-Generated Content',
          body: 'Workout plans, nutrition guidance, and feedback are generated by an AI model '
              'based on the information you provide. They are general fitness suggestions, not '
              'medical advice. Consult a qualified professional before starting any new exercise '
              'or nutrition program, especially if you have a pre-existing health condition.',
        ),
        LegalSection(
          heading: '3. Your Account',
          body: 'You are responsible for keeping your login credentials secure and for all '
              'activity under your account. Notify us immediately if you suspect unauthorised access.',
        ),
        LegalSection(
          heading: '4. Acceptable Use',
          body: 'You agree not to misuse the app — including attempting to reverse-engineer the '
              'AI models, scrape data, or use the service for any unlawful purpose.',
        ),
        LegalSection(
          heading: '5. Subscription & Billing',
          body: 'Where applicable, subscription fees are billed in advance on a recurring basis. '
              'You can cancel at any time; access continues until the end of the current billing period.',
        ),
        LegalSection(
          heading: '6. Changes to These Terms',
          body: 'We may update these terms from time to time. Continued use of the app after a '
              'change constitutes acceptance of the revised terms.',
        ),
        LegalSection(
          heading: '7. Contact',
          body: 'Questions about these terms? Reach us at support@befitai.app.',
        ),
      ],
    );
  }
}

// ── Privacy Policy ────────────────────────────────────────────────────────────────

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentPage(
      title: 'Privacy Policy',
      icon: Icons.privacy_tip_outlined,
      lastUpdated: 'June 2026',
      sections: const [
        LegalSection(
          heading: '1. What We Collect',
          body: 'Account details (name, email), profile data you provide during onboarding '
              '(goal, experience, height, weight, gender, date of birth), physique and food photos '
              'you upload for AI analysis, and workout/nutrition activity you log in the app.',
        ),
        LegalSection(
          heading: '2. How We Use Your Data',
          body: 'Your data is used to generate personalised workout plans, body composition '
              'analysis, nutrition feedback, and to track your progress (streaks, saved plans, '
              'progress photos). Photos are sent to our AI provider for analysis and are not used '
              'to train public models.',
        ),
        LegalSection(
          heading: '3. Where Your Data Lives',
          body: 'Account and activity data is stored in our Supabase-hosted database, secured by '
              'row-level security tied to your account. Some data (saved plans, progress photos, '
              'local preferences) is also cached on your device for offline access.',
        ),
        LegalSection(
          heading: '4. Sharing',
          body: 'We do not sell your personal data. Data is shared only with the AI providers '
              'necessary to generate your plans/analysis, and with infrastructure providers '
              '(hosting, database) under standard data-processing agreements.',
        ),
        LegalSection(
          heading: '5. Your Rights',
          body: 'You can request a copy of your data, or delete your account and associated data '
              'at any time from Profile → Account → Delete Account.',
        ),
        LegalSection(
          heading: '6. Children\'s Privacy',
          body: 'BeFit AI is not directed at children under 16. We do not knowingly collect data '
              'from children.',
        ),
        LegalSection(
          heading: '7. Contact',
          body: 'Questions about how your data is handled? Reach us at support@befitai.app.',
        ),
      ],
    );
  }
}
