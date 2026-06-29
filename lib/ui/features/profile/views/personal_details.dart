import 'package:fitness/domain/models/profile.dart';
import 'package:fitness/ui/core/di.dart' as di;
import 'package:fitness/ui/features/profile/view_models/profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ── Design tokens (matches profile_page.dart / BeFit dark theme) ───────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kBlue   = Color(0xFF4D9EFF);
const _kDim    = Color(0x80FFFFFF);

class PersonalDetailsPage extends StatelessWidget {
  const PersonalDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => di.sl<ProfileViewModel>()..loadProfile(),
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Personal Details',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        body: SafeArea(
          child: Consumer<ProfileViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading || vm.profile == null) {
                return const Center(child: CircularProgressIndicator(color: _kLime));
              }
              if (vm.error != null) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent.withValues(alpha: 0.8)),
                    const SizedBox(height: 16),
                    Text('Error loading profile',
                        style: GoogleFonts.poppins(fontSize: 15, color: Colors.white)),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => vm.refresh(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(color: _kLime, borderRadius: BorderRadius.circular(12)),
                        child: Text('Retry',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
                      ),
                    ),
                  ]),
                );
              }

              final profile = vm.profile!;
              final metrics = _BodyMetrics.fromProfile(profile);

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                physics: const BouncingScrollPhysics(),
                children: [
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: 24),

                  // ── BMI insight card ───────────────────────────────────────
                  if (metrics.bmi != null) ...[
                    _BmiCard(metrics: metrics),
                    const SizedBox(height: 24),
                  ],

                  // ── Body metrics grid ───────────────────────────────────────
                  _SectionLabel(label: 'Body Metrics', icon: Icons.straighten_rounded),
                  const SizedBox(height: 12),
                  _MetricsGrid(profile: profile, metrics: metrics),
                  const SizedBox(height: 24),

                  // ── Fitness profile ──────────────────────────────────────────
                  _SectionLabel(label: 'Fitness Profile', icon: Icons.fitness_center_rounded),
                  const SizedBox(height: 12),
                  _DetailCard(
                    icon: Icons.flag_outlined,
                    label: 'Primary Goal',
                    value: _capitalize(profile.goal),
                    accent: _kLime,
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    icon: Icons.bar_chart_rounded,
                    label: 'Experience Level',
                    value: _capitalize(profile.experience),
                    accent: _kBlue,
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    icon: Icons.calendar_view_week_rounded,
                    label: 'Training Days / Week',
                    value: profile.workoutDays != null ? '${profile.workoutDays} days' : 'Not set',
                    accent: const Color(0xFFFFAA00),
                  ),
                  const SizedBox(height: 24),

                  // ── Personal info ─────────────────────────────────────────
                  _SectionLabel(label: 'Personal Info', icon: Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _DetailCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date of Birth',
                    value: _formatDob(profile.dob),
                    sub: profile.age != null ? '${profile.age} years old' : null,
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    icon: Icons.person_outline_rounded,
                    label: 'Gender',
                    value: _capitalize(profile.gender),
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    icon: Icons.height_rounded,
                    label: 'Height',
                    value: _format(profile.height),
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Weight',
                    value: _format(profile.weight),
                  ),

                  if (metrics.bmr != null) ...[
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'Estimated Energy Needs', icon: Icons.local_fire_department_rounded),
                    const SizedBox(height: 12),
                    _BmrCard(metrics: metrics),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return 'Not set';
    try {
      final parts = dob.split('-');
      if (parts.length != 3) return dob;
      const months = ['January','February','March','April','May','June','July',
        'August','September','October','November','December'];
      return '${months[int.parse(parts[1]) - 1]} ${parts[2]}, ${parts[0]}';
    } catch (_) { return dob; }
  }

  static String _capitalize(String? value) {
    if (value == null || value.isEmpty) return 'Not set';
    return value.substring(0, 1).toUpperCase() + value.substring(1).toLowerCase();
  }

  static String _format(String? value) => (value == null || value.isEmpty) ? 'Not set' : value;
}

// ── Header: avatar + name + email ───────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final ProfileEntity profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kLime.withValues(alpha: 0.12),
            border: Border.all(color: _kLime.withValues(alpha: 0.3), width: 1.5),
          ),
          child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
              ? ClipOval(child: Image.network(profile.avatarUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initial()))
              : _initial(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name?.isNotEmpty == true ? profile.name! : 'Your Profile',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 3),
              if (profile.email != null)
                Text(profile.email!,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, color: _kDim)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _initial() => Center(
        child: Text(profile.initial,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: _kLime)),
      );
}

// ── Section label ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _kDim),
        const SizedBox(width: 6),
        Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700, color: _kDim, letterSpacing: 0.8)),
      ],
    );
  }
}

// ── Detail card ───────────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color accent;
  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.accent = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: _kDim)),
            const SizedBox(height: 3),
            Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
        if (sub != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(sub!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _kDim)),
          ),
      ]),
    );
  }
}

// ── Body metrics grid (2x2 quick stats) ──────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  final ProfileEntity profile;
  final _BodyMetrics metrics;
  const _MetricsGrid({required this.profile, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _MetricChip(
        icon: Icons.cake_outlined,
        label: 'Age',
        value: profile.age != null ? '${profile.age}' : '—',
        unit: 'yrs',
      )),
      const SizedBox(width: 10),
      Expanded(child: _MetricChip(
        icon: Icons.height_rounded,
        label: 'Height',
        value: metrics.heightCm != null ? metrics.heightCm!.toStringAsFixed(0) : '—',
        unit: 'cm',
      )),
      const SizedBox(width: 10),
      Expanded(child: _MetricChip(
        icon: Icons.monitor_weight_outlined,
        label: 'Weight',
        value: metrics.weightKg != null ? metrics.weightKg!.toStringAsFixed(0) : '—',
        unit: 'kg',
      )),
    ]);
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  const _MetricChip({required this.icon, required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(children: [
        Icon(icon, size: 17, color: _kDim),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(children: [
            TextSpan(text: value, style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            TextSpan(text: ' $unit', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w500, color: _kDim)),
          ]),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: _kDim)),
      ]),
    );
  }
}

// ── BMI insight card ──────────────────────────────────────────────────────────────

class _BmiCard extends StatelessWidget {
  final _BodyMetrics metrics;
  const _BmiCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final bmi = metrics.bmi!;
    final category = metrics.bmiCategory!;
    final color = metrics.bmiColor!;
    // BMI visual range 15–40 mapped to 0.0–1.0
    final fraction = ((bmi - 15) / (40 - 15)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.monitor_heart_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Body Mass Index', style: GoogleFonts.inter(fontSize: 12, color: _kDim)),
              const SizedBox(height: 2),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(bmi.toStringAsFixed(1),
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(category, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(children: [
            Container(height: 6, color: Colors.white.withValues(alpha: 0.07)),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(height: 6, decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color]))),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('15', style: GoogleFonts.inter(fontSize: 10, color: _kDim)),
          Text('Underweight · Normal · Overweight · Obese',
              style: GoogleFonts.inter(fontSize: 9, color: _kDim)),
          Text('40', style: GoogleFonts.inter(fontSize: 10, color: _kDim)),
        ]),
      ]),
    );
  }
}

// ── BMR / daily energy card ──────────────────────────────────────────────────────

class _BmrCard extends StatelessWidget {
  final _BodyMetrics metrics;
  const _BmrCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final bmr = metrics.bmr!;
    final maintenance = (bmr * 1.4).round(); // light activity multiplier
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Resting (BMR)', style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
            const SizedBox(height: 4),
            Text('${bmr.round()} kcal', style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 2),
            Text('per day at rest', style: GoogleFonts.inter(fontSize: 10, color: _kDim)),
          ]),
        ),
        Container(width: 1, height: 40, color: _kBorder),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Maintenance', style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
            const SizedBox(height: 4),
            Text('$maintenance kcal', style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w800, color: _kLime)),
            const SizedBox(height: 2),
            Text('with light activity', style: GoogleFonts.inter(fontSize: 10, color: _kDim)),
          ]),
        ),
      ]),
    );
  }
}

// ── Body metrics calculator ──────────────────────────────────────────────────────

class _BodyMetrics {
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String? bmiCategory;
  final Color? bmiColor;
  final double? bmr;

  _BodyMetrics({this.heightCm, this.weightKg, this.bmi, this.bmiCategory, this.bmiColor, this.bmr});

  factory _BodyMetrics.fromProfile(ProfileEntity profile) {
    final heightCm = _parseHeightToCm(profile.height);
    final weightKg = _parseWeightToKg(profile.weight);

    double? bmi;
    String? category;
    Color? color;
    if (heightCm != null && weightKg != null && heightCm > 0) {
      final meters = heightCm / 100;
      bmi = weightKg / (meters * meters);
      if (bmi < 18.5) { category = 'Underweight'; color = const Color(0xFF4D9EFF); }
      else if (bmi < 25) { category = 'Normal'; color = const Color(0xFFCCFF00); }
      else if (bmi < 30) { category = 'Overweight'; color = const Color(0xFFFFAA00); }
      else { category = 'Obese'; color = const Color(0xFFFF5C5C); }
    }

    double? bmr;
    if (heightCm != null && weightKg != null && profile.age != null) {
      // Mifflin-St Jeor equation
      final genderOffset = (profile.gender?.toLowerCase() == 'female') ? -161 : 5;
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * profile.age!) + genderOffset;
    }

    return _BodyMetrics(
      heightCm: heightCm,
      weightKg: weightKg,
      bmi: bmi,
      bmiCategory: category,
      bmiColor: color,
      bmr: bmr,
    );
  }

  static double? _parseHeightToCm(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final s = raw.toLowerCase().trim();
    final numMatch = RegExp(r'[\d.]+').allMatches(s).map((m) => double.tryParse(m.group(0)!)).toList();
    if (s.contains('cm')) return numMatch.isNotEmpty ? numMatch.first : null;
    if (s.contains('ft') || s.contains("'")) {
      // e.g. "5ft 11in" or "5'11"
      if (numMatch.length >= 2) {
        final feet = numMatch[0] ?? 0;
        final inches = numMatch[1] ?? 0;
        return (feet * 30.48) + (inches * 2.54);
      }
      if (numMatch.length == 1) return (numMatch[0] ?? 0) * 30.48;
    }
    if (s.contains('in')) return numMatch.isNotEmpty ? (numMatch.first ?? 0) * 2.54 : null;
    // Bare number: assume cm if > 100, else treat as meters
    if (numMatch.isNotEmpty && numMatch.first != null) {
      final v = numMatch.first!;
      return v > 100 ? v : v * 100;
    }
    return null;
  }

  static double? _parseWeightToKg(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final s = raw.toLowerCase().trim();
    final match = RegExp(r'[\d.]+').firstMatch(s);
    if (match == null) return null;
    final value = double.tryParse(match.group(0)!);
    if (value == null) return null;
    if (s.contains('lb')) return value * 0.453592;
    return value; // assume kg
  }
}
