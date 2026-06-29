import 'package:fitness/l10n/generated/app_localizations.dart';
import 'package:fitness/ui/core/locale/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ── Design tokens (matches profile_page.dart / BeFit dark theme) ───────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kDim    = Color(0x80FFFFFF);

/// Language entries show their **native** name, not a translation of it —
/// "English" / "Español" stay the same regardless of the app's current
/// locale, so the user can always recognise the language they're looking
/// for. (Translating "English" into the active locale would render it as
/// "Inglés" while in Spanish mode, which defeats the point of the picker.)
const _languages = [
  (code: 'en', flag: '🇺🇸', native: 'English'),
  (code: 'es', flag: '🇪🇸', native: 'Español'),
];

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(t.languagePageTitle,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: SafeArea(
        child: Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            final currentCode = localeProvider.locale?.languageCode ??
                Localizations.localeOf(context).languageCode;
            final current = _languages.firstWhere(
              (l) => l.code == currentCode,
              orElse: () => _languages.first,
            );

            return ListView(
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
                    child: const Icon(Icons.translate_rounded, color: _kLime, size: 28),
                  ),
                ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.85, 0.85)),

                const SizedBox(height: 16),
                Text(
                  t.languagePageSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: _kDim),
                ).animate(delay: 80.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: 28),

                // ── Current selection summary ─────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kLime.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kLime.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Text(current.flag, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('CURRENTLY USING',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                                color: _kLime, letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        Text(current.native,
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ]),
                    ),
                  ]),
                ).animate(delay: 120.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 24),
                _SectionLabel(label: 'Available Languages', icon: Icons.public_rounded),
                const SizedBox(height: 12),

                ..._languages.asMap().entries.map((entry) {
                  final i = entry.key;
                  final lang = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LanguageOption(
                      flag: lang.flag,
                      label: lang.native,
                      isSelected: currentCode == lang.code,
                      onTap: () => localeProvider.setLocale(Locale(lang.code)),
                    ),
                  ).animate(delay: Duration(milliseconds: 160 + i * 60))
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
                }),

                const SizedBox(height: 16),

                // ── More languages coming hint ────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(children: [
                    Icon(Icons.auto_awesome_rounded, size: 18, color: _kDim),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'More languages are on the way. Tell us which one you\'d like to see next.',
                        style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: _kDim),
                      ),
                    ),
                  ]),
                ).animate(delay: 320.ms).fadeIn(duration: 300.ms),
              ],
            );
          },
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

// ── Language option card ───────────────────────────────────────────────────────────

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _kLime.withValues(alpha: 0.1) : _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _kLime.withValues(alpha: 0.5) : _kBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _kLime.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: Text(flag, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _kLime : Colors.white,
                )),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isSelected
                ? const Icon(Icons.check_circle_rounded, color: _kLime, size: 22, key: ValueKey('sel'))
                : Icon(Icons.circle_outlined, color: Colors.white.withValues(alpha: 0.15), size: 22, key: const ValueKey('unsel')),
          ),
        ]),
      ),
    );
  }
}
