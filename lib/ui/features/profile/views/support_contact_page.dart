import 'package:fitness/ui/core/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Design tokens (matches profile_page.dart / BeFit dark theme) ───────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kDim    = Color(0x80FFFFFF);

const _faqs = [
  (
    'How do I generate a new workout plan?',
    'Go to Profile → Adjust workout plan, update your goal/stats, then take or upload a '
        'physique photo on the next screen to generate a fresh plan.',
  ),
  (
    'Why did my progress photo disappear after restarting the app?',
    'This was a known local-storage bug that has since been fixed. If you still see a missing '
        'photo, try re-adding it — it will persist correctly going forward.',
  ),
  (
    'How is my streak calculated?',
    'Your streak counts consecutive days with at least one completed workout session, '
        'recalculated automatically whenever you finish a workout.',
  ),
];

class SupportContactPage extends StatelessWidget {
  const SupportContactPage({super.key});

  Future<void> _emailSupport(BuildContext context, {String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: Constant.supportEmail,
      query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
    );
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open a mail app. Email us at ${Constant.supportEmail}')),
      );
    }
  }

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: Constant.supportEmail));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email address copied')),
      );
    }
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
        title: Text('Support',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          physics: const BouncingScrollPhysics(),
          children: [
            // ── Header icon ───────────────────────────────────────────
            Center(
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kLime.withValues(alpha: 0.1),
                  border: Border.all(color: _kLime.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.support_agent_rounded, color: _kLime, size: 30),
              ),
            ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.85, 0.85)),

            const SizedBox(height: 16),
            Text(
              'We\'re here to help',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
            ).animate(delay: 60.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 6),
            Text(
              'Reach out and we\'ll get back to you within 1-2 business days.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: _kDim),
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // ── Email card ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorder),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _kLime.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.email_outlined, color: _kLime, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Support Email', style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
                    const SizedBox(height: 2),
                    Text(Constant.supportEmail,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
                GestureDetector(
                  onTap: () => _copyEmail(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                  ),
                ),
              ]),
            ).animate(delay: 140.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 14),

            // ── Email us CTA ───────────────────────────────────────────
            GestureDetector(
              onTap: () => _emailSupport(context, subject: 'BeFit AI Support Request'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _kLime,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _kLime.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 5))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.send_rounded, color: Colors.black, size: 17),
                  const SizedBox(width: 8),
                  Text('Email Us', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
                ]),
              ),
            ).animate(delay: 180.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 28),
            _SectionLabel(label: 'Frequently Asked', icon: Icons.help_outline_rounded),
            const SizedBox(height: 12),

            ..._faqs.asMap().entries.map((entry) {
              final i = entry.key;
              final (question, answer) = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FaqTile(question: question, answer: answer),
              ).animate(delay: Duration(milliseconds: 220 + i * 60)).fadeIn(duration: 280.ms);
            }),
          ],
        ),
      ),
    );
  }
}

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

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _expanded ? _kLime.withValues(alpha: 0.3) : _kBorder),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Expanded(
                child: Text(widget.question,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: _kDim, size: 20),
              ),
            ]),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(widget.answer,
                  style: GoogleFonts.inter(fontSize: 12, height: 1.5, color: _kDim)),
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ]),
    );
  }
}
