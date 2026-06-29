import 'package:fitness/ui/core/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Design tokens (matches profile_page.dart / BeFit dark theme) ───────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kDim    = Color(0x80FFFFFF);

const _categories = [
  ('Feature Idea', Icons.lightbulb_outline_rounded),
  ('Bug Report', Icons.bug_report_outlined),
  ('Improvement', Icons.trending_up_rounded),
  ('Other', Icons.more_horiz_rounded),
];

/// Lets the user describe a feature request / bug report and hands it off
/// to their mail client (mailto:) addressed to support, since there's no
/// dedicated feedback-intake backend endpoint yet.
class FeatureRequestPage extends StatefulWidget {
  const FeatureRequestPage({super.key});

  @override
  State<FeatureRequestPage> createState() => _FeatureRequestPageState();
}

class _FeatureRequestPageState extends State<FeatureRequestPage> {
  String _category = _categories.first.$1;
  final _titleCtl = TextEditingController();
  final _detailsCtl = TextEditingController();

  @override
  void dispose() {
    _titleCtl.dispose();
    _detailsCtl.dispose();
    super.dispose();
  }

  bool get _isValid => _titleCtl.text.trim().isNotEmpty && _detailsCtl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title and a short description.')),
      );
      return;
    }

    final subject = '[$_category] ${_titleCtl.text.trim()}';
    final body = _detailsCtl.text.trim();
    final uri = Uri(
      scheme: 'mailto',
      path: Constant.supportEmail,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    final launched = await launchUrl(uri);
    if (!mounted) return;

    if (launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening your mail app to send the request…')),
      );
      Navigator.of(context).maybePop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open a mail app. Email us directly at ${Constant.supportEmail}')),
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
        title: Text('Feature Request',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                Center(
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kLime.withValues(alpha: 0.1),
                      border: Border.all(color: _kLime.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded, color: _kLime, size: 28),
                  ),
                ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.85, 0.85)),

                const SizedBox(height: 16),
                Text(
                  'Got an idea to make BeFit AI better? Tell us about it below.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: _kDim),
                ).animate(delay: 60.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: 24),
                _SectionLabel(label: 'Category', icon: Icons.category_outlined),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final (label, icon) = cat;
                    final isSelected = _category == label;
                    return GestureDetector(
                      onTap: () => setState(() => _category = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? _kLime.withValues(alpha: 0.1) : _kCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? _kLime.withValues(alpha: 0.5) : _kBorder),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(icon, size: 14, color: isSelected ? _kLime : _kDim),
                          const SizedBox(width: 6),
                          Text(label, style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: isSelected ? _kLime : Colors.white)),
                        ]),
                      ),
                    );
                  }).toList(),
                ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: 24),
                _SectionLabel(label: 'Title', icon: Icons.short_text_rounded),
                const SizedBox(height: 10),
                _TextField(controller: _titleCtl, hint: 'e.g. Dark mode for the workout timer', maxLines: 1),

                const SizedBox(height: 24),
                _SectionLabel(label: 'Details', icon: Icons.notes_rounded),
                const SizedBox(height: 10),
                _TextField(
                  controller: _detailsCtl,
                  hint: 'What would you like to see, and why would it help your workouts?',
                  maxLines: 6,
                ),
              ],
            ),
          ),
          // ── Bottom CTA ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: _kLime,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _kLime.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  Text('Submit Request', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
                ]),
              ),
            ),
          ),
        ]),
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

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _TextField({required this.controller, required this.hint, required this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: _kDim),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
