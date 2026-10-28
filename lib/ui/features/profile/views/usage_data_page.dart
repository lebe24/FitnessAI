import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_preferences.dart';
import 'package:fitness/ui/features/profile/views/legal_document_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens (matches profile_page.dart / BeFit dark theme) ───────────────
const _kBg = Color(0xFF0A0C12);
const _kCard = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime = Color(0xFFCCFF00);
const _kDim = Color(0x80FFFFFF);

/// Lets the user see what usage analytics collects and turn it off.
///
/// The switch applies immediately and is remembered on the device. Turning it
/// off stops collection entirely — the SDK is told to opt out, so nothing more
/// is queued or sent, not merely hidden from reports.
class UsageDataPage extends StatefulWidget {
  const UsageDataPage({super.key});

  @override
  State<UsageDataPage> createState() => _UsageDataPageState();
}

class _UsageDataPageState extends State<UsageDataPage> {
  bool? _enabled; // null while the saved choice loads

  @override
  void initState() {
    super.initState();
    AnalyticsPreferences.isEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  Future<void> _set(bool value) async {
    setState(() => _enabled = value);
    // Remember the choice first, so it holds even if the SDK is not running
    // (for example a build with no analytics key).
    await AnalyticsPreferences.setEnabled(value);
    try {
      await Analytics.service.setEnabled(value);
    } catch (e) {
      debugPrint('UsageDataPage: could not apply choice — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Usage data',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          physics: const BouncingScrollPhysics(),
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kLime.withValues(alpha: 0.1),
                  border: Border.all(
                      color: _kLime.withValues(alpha: 0.3), width: 1.5),
                ),
                child:
                    const Icon(Icons.insights_rounded, color: _kLime, size: 28),
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            Text(
              'BeFit AI records which features get used, so we can find what '
              'is confusing or broken and fix it.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 13, height: 1.5, color: _kDim),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorder),
              ),
              child: SwitchListTile.adaptive(
                value: enabled ?? true,
                onChanged: enabled == null ? null : _set,
                activeThumbColor: _kLime,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                title: Text('Share usage data',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    enabled == false
                        ? 'Off. Nothing about how you use the app is sent.'
                        : 'On. You can turn this off at any time.',
                    style: GoogleFonts.inter(fontSize: 12, color: _kDim),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _Block(
              title: 'What is recorded',
              body: 'Which screens you open, which features you use, whether a '
                  'scan or plan succeeded, how long it took, and the goal, '
                  'experience level and training days you pick. Each event is '
                  'tied to a random account ID.',
            ),
            const SizedBox(height: 14),
            _Block(
              title: 'What is never recorded',
              body: 'Your name or email, your photos, what you type to the '
                  'coach, your notes, your gender, age, weight or body '
                  'measurements, or '
                  'anything about other apps. It is not sold or used for ads.',
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                ),
                child: Text('Read the Privacy Policy',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kLime)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final String body;
  const _Block({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(body,
              style:
                  GoogleFonts.inter(fontSize: 12.5, height: 1.5, color: _kDim)),
        ],
      ),
    );
  }
}
