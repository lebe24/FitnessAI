import 'package:fitness/ui/core/constants/constant.dart';
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

// ── Terms of Use ──────────────────────────────────────────────────────────────
//
// These mirror befit_web/app/(legal)/terms and /privacy section for section,
// with the same headings and the same substance. A reviewer following the link
// in the App Store description reads the website; a reviewer tapping through
// from the Billing screen reads this. The two disagreeing is its own finding.
//
// Sections 5 to 7 carry what guideline 3.1.2(c) actually checks for: what is
// sold, how long it runs, that it renews by itself, when the charge lands, and
// how to stop it.

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  /// The document itself, separate from the page that renders it.
  ///
  /// Exposed so the clauses App Review requires can be asserted in a test. A
  /// missing sentence here is not a visual bug — it is a rejection, and it is
  /// exactly the kind of thing an edit for brevity removes by accident.
  static List<LegalSection> get sections => [
        LegalSection(
          heading: '1. Who you are agreeing with',
          body: 'These terms are an agreement between you and ${Constant.legalEntity}, who '
              'provides the BeFit AI app. "We" and "us" mean ${Constant.legalEntity}; "you" '
              'means the person using the app.\n\n'
              'If anything here is unclear, email us at ${Constant.supportEmail} before you '
              'subscribe rather than after.',
        ),
        const LegalSection(
          heading: '2. Accepting these terms',
          body: 'Creating an account or using the app means you accept these terms. If you do '
              'not accept them, do not use BeFit AI.\n\n'
              'We may update them — see section 13 for how you will find out.',
        ),
        const LegalSection(
          heading: '3. Who can use BeFit AI',
          body: 'You must be at least 16 years old. The app gives training and nutrition '
              'guidance, which is not appropriate for children.\n\n'
              'You also need to be capable of exercising safely. If you have a health '
              'condition, are pregnant, are recovering from injury, or have been told by a '
              'doctor to limit physical activity, speak to a qualified professional before '
              'following any plan the app produces.',
        ),
        const LegalSection(
          heading: '4. Your account',
          body: 'You are responsible for keeping your sign-in details secure and for what '
              'happens under your account. Tell us straight away if you think someone else '
              'has access to it.\n\n'
              'One account is for one person. Sharing an account, or sharing a subscription '
              'across several people, is not permitted.',
        ),
        const LegalSection(
          heading: '5. Subscriptions',
          body: 'BeFit AI is free to download, and building your first plan is free. Full '
              'access — adaptive plans, unlimited logging, coach chat, nutrition scanning, '
              'body composition and analytics — requires a paid subscription.\n\n'
              'Two subscriptions are offered: BeFit AI Pro — Monthly (1 month) and BeFit AI '
              'Pro — Yearly (1 year). The price of each is shown in the app, in your local '
              'currency, before you confirm anything. We do not take payment ourselves — '
              'purchases are processed by Apple and charged to your Apple Account.\n\n'
              'Payment is taken when you confirm the purchase. Your subscription then renews '
              'automatically for the same length at the same price until you cancel.',
        ),
        const LegalSection(
          heading: '6. Free trial',
          body: 'New subscribers are offered a 1 week free trial before the first payment. '
              'You get full access during it and are charged nothing until it ends.\n\n'
              'The trial converts into a paid subscription automatically when it ends, unless '
              'you cancel at least 24 hours before that point. If you buy a subscription '
              'while a trial is still running, any unused part of the trial is forfeited.\n\n'
              'One trial per person. Switching between the monthly and yearly plans does not '
              'start a new one.',
        ),
        const LegalSection(
          heading: '7. Cancelling, renewing and refunds',
          body: 'Your subscription renews automatically unless auto-renew is turned off at '
              'least 24 hours before the end of the current period. Your Apple Account is '
              'charged for the renewal within the 24 hours before the period ends.\n\n'
              'Cancel at any time in your Apple Account settings: Settings on your iPhone, '
              'then your name, then Subscriptions, then BeFit AI. Deleting the app does not '
              'cancel a subscription, and neither does deleting your BeFit account.\n\n'
              'Cancelling stops the next payment. It does not end the period you have already '
              'paid for — you keep full access until that period runs out, and we do not '
              'pro-rate or refund part-used periods.\n\n'
              'Refunds are handled by Apple, not by us, and are requested through '
              'reportaproblem.apple.com.',
        ),
        const LegalSection(
          heading: '8. What BeFit AI is, and is not',
          body: 'Your plans, coaching replies and motivational messages are generated by an '
              'AI model from the information you give us and the sessions you log. They are '
              'general fitness and nutrition guidance.\n\n'
              'They are not medical advice, a diagnosis, or a treatment plan, and no part of '
              'the app is a substitute for a doctor, physiotherapist or registered dietitian. '
              'AI output can be wrong. Use your judgement, and stop if something hurts.\n\n'
              'You take part in physical exercise at your own risk.',
        ),
        const LegalSection(
          heading: '9. Using the app properly',
          body: 'Do not attempt to reverse-engineer the app or the models behind it, scrape '
              'or bulk-export data, resell access, interfere with the service, or use it for '
              'anything unlawful.\n\n'
              'Do not submit photographs of anyone other than yourself, and do not submit '
              'content that is illegal or that you have no right to share.',
        ),
        const LegalSection(
          heading: '10. Content and ownership',
          body: 'The app, its design, and the systems that generate your plans remain ours. '
              'Nothing here transfers ownership of them to you.\n\n'
              'What you put in stays yours — your photos, your logged sessions, your notes. '
              'You give us permission to process them for the purpose of running the app for '
              'you, as described in our Privacy Policy, and for nothing else.',
        ),
        const LegalSection(
          heading: '11. Ending your access',
          body: 'You can stop at any time by cancelling your subscription and deleting your '
              'account from Profile, then Delete Account.\n\n'
              'We may suspend or close an account that breaks these terms, or where we are '
              'required to by law. If we close your account and you have paid for a period '
              'you have not used, we will refund the unused part unless the closure was for a '
              'serious breach.',
        ),
        const LegalSection(
          heading: '12. Liability',
          body: 'The app is provided as it is. We do not promise it will be uninterrupted or '
              'error-free, and we do not guarantee any particular fitness result — outcomes '
              'depend on what you actually do.\n\n'
              'Nothing in these terms limits liability for death or personal injury caused by '
              'our negligence, for fraud, or for anything else that cannot lawfully be '
              'limited. Subject to that, our total liability to you is limited to what you '
              'have paid us in the twelve months before the claim.',
        ),
        const LegalSection(
          heading: '13. Changes to these terms',
          body: 'We may update these terms as the app changes. The date at the top of this '
              'page always shows the current version.\n\n'
              'If a change materially affects your rights, we will tell you in the app or by '
              'email before it takes effect. Continuing to use BeFit AI after that means you '
              'accept the new version.',
        ),
        LegalSection(
          heading: '14. Governing law',
          body: 'These terms are governed by the law of ${Constant.legalJurisdiction}, and '
              'disputes will be heard by its courts. If you are a consumer, this does not '
              'remove any protection you have under the law of the country you live in.',
        ),
        LegalSection(
          heading: '15. Contact',
          body: 'Questions about these terms, your subscription, or your account: '
              '${Constant.supportEmail}. A person reads every message.',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return LegalDocumentPage(
      title: 'Terms of Use',
      icon: Icons.description_outlined,
      lastUpdated: Constant.legalLastUpdated,
      sections: sections,
    );
  }
}

// ── Privacy Policy ────────────────────────────────────────────────────────────
//
// Must agree with two other things or it becomes a liability rather than a
// protection: the App Privacy questionnaire in App Store Connect, and the
// website's policy. Change one, change all three.

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  /// See the note on [TermsAndConditionsPage.sections].
  static List<LegalSection> get sections => [
        LegalSection(
          heading: '1. Who handles your data',
          body: '${Constant.legalEntity} provides the BeFit AI app, and decides how and '
              'why your personal data is processed. That makes us responsible for it.\n\n'
              'For anything in this policy, including a request to see or delete your data, '
              'write to ${Constant.supportEmail}.',
        ),
        const LegalSection(
          heading: '2. What we collect',
          body: 'Account details. Your name and email address. If you use Sign in with Apple '
              'and choose to hide your address, we receive a relay address instead of your '
              'real one — see section 5.\n\n'
              'What you tell us during onboarding. Your goal, training experience, how many '
              'days a week you can train, the equipment you can reach, your height, weight, '
              'gender and date of birth.\n\n'
              'What you log. Workouts, exercises, sets, reps, weights, session durations, '
              'streaks, notes and any feedback you give on a session.\n\n'
              'Photos you choose to take. Meal photos for calorie and macro estimates, '
              'physique photos for body-composition analysis, equipment photos for the gym '
              'scanner, and progress photos. Progress photos are stored on your device and '
              'are not uploaded.\n\n'
              'Technical data. Device and app version, and error reports when something fails '
              '— these include the type of error and where it happened, so we can fix it.',
        ),
        const LegalSection(
          heading: '3. Why we collect it',
          body: 'To build and rebuild your training plan around what you have actually done, '
              'to answer your questions in the coach chat with your real history in view, to '
              'estimate what is on your plate, to show your progress over time, and to send '
              'the motivational messages you have asked for in the tone you chose.\n\n'
              'To run the subscription: your entitlement is checked so paid features unlock '
              'for you and not for someone else.\n\n'
              'To keep the app working. Error reports tell us what is broken. We do not use '
              'any of this for advertising, and we do not build a profile of you for anyone '
              "else's purposes.",
        ),
        const LegalSection(
          heading: '4. AI processing',
          body: 'Your plans, coaching replies and analysis are generated by AI models run by '
              'our providers. To produce them, the relevant parts of your data — your '
              'profile, your recent sessions, the photo you just took — are sent to those '
              'providers for processing.\n\n'
              'Your data is not used to train publicly available models. Providers act on our '
              'instructions under contract and cannot use your content for their own purposes.',
        ),
        const LegalSection(
          heading: '5. Sign in with Apple and private relay',
          body: 'If you sign in with Apple you can choose to hide your email address. Apple '
              'then gives us a relay address that forwards to you, and we never see your real '
              'one. Everything in the app works normally with a relay address.\n\n'
              'Apple sends us your name only on the very first sign-in, and only if you allow '
              'it. If you decline, your profile simply has no name until you set one.',
        ),
        const LegalSection(
          heading: '6. Where your data is stored',
          body: 'Account and training data is held in our Supabase-hosted Postgres database, '
              'protected by row-level security so that a signed-in user can reach their own '
              "rows and no one else's.\n\n"
              'Our backend runs on Google Cloud Run in the United States, which is where AI '
              'generation happens. If you are in the UK or the EEA, that means your data is '
              'transferred outside your region; those transfers rely on standard contractual '
              'clauses.\n\n'
              'Some data is also cached on your device so the app works offline — your saved '
              'plans, your preferences, your chat history and your progress photos.',
        ),
        const LegalSection(
          heading: '7. Who we share it with',
          body: 'Only the providers needed to run the service: our database and hosting '
              'providers, the AI providers described in section 4, Apple for payments and '
              'subscription status, and RevenueCat, which tells us whether your subscription '
              'is active.\n\n'
              'Each acts as our processor under a data-processing agreement. We may also '
              'disclose data where the law requires it.',
        ),
        const LegalSection(
          heading: '8. What we never do',
          body: 'We do not sell your personal data. We do not share it with advertisers or '
              'data brokers. We do not track you across other apps or websites, and we do not '
              'use your training history or your photos for anything other than running BeFit '
              'AI for you.',
        ),
        LegalSection(
          heading: '9. How long we keep it',
          body: 'Your account data is kept while your account exists. Delete your account '
              'from Profile, then Delete Account, and your profile, training history, chat '
              'history and uploaded photos are removed with it. Progress photos held on your '
              'device go when you delete the app.\n\n'
              'Deletion cannot be undone. Backups are overwritten on a rolling basis and '
              'clear within 30 days. We may keep a minimal record of a transaction where tax '
              'or accounting law requires it.\n\n'
              'If you cannot get into the app to delete your account, email '
              '${Constant.supportEmail} and we will do it for you.',
        ),
        LegalSection(
          heading: '10. Your rights',
          body: 'You can ask for a copy of your data, ask us to correct it, ask us to delete '
              'it, ask us to restrict how we use it, object to a particular use, or ask for '
              'it in a portable format. Where we rely on your consent — for photo analysis, '
              'for example — you can withdraw it at any time by not using that feature.\n\n'
              'Write to ${Constant.supportEmail} and we will respond within 30 days. If you '
              'think we have handled your data badly, you can also complain to the data '
              'protection authority where you live; in ${Constant.legalJurisdiction} that is '
              "the Information Commissioner's Office.",
        ),
        const LegalSection(
          heading: '11. Children',
          body: 'BeFit AI is not intended for anyone under 16 and we do not knowingly collect '
              'their data. If you believe a child has created an account, tell us and we will '
              'remove it.',
        ),
        const LegalSection(
          heading: '12. Security',
          body: 'Data is encrypted in transit. Database access is scoped per user by '
              'row-level security, and our own access to production data is limited to what '
              'is needed to run and support the service.\n\n'
              'No system is perfectly secure. If a breach affects your data, we will tell you '
              'and the relevant authority as the law requires.',
        ),
        const LegalSection(
          heading: '13. Changes to this policy',
          body: 'We will update this page when what we collect or how we use it changes. The '
              'date at the top always reflects the current version, and we will tell you in '
              'the app before any material change takes effect.',
        ),
        LegalSection(
          heading: '14. Contact',
          body: 'Questions about your data, or a request to exercise any of the rights above: '
              '${Constant.supportEmail}.',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return LegalDocumentPage(
      title: 'Privacy Policy',
      icon: Icons.privacy_tip_outlined,
      lastUpdated: Constant.legalLastUpdated,
      sections: sections,
    );
  }
}
