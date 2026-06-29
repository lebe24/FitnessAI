import 'dart:io';

import 'package:fitness/l10n/generated/app_localizations.dart';
import 'package:fitness/ui/core/di.dart' as di;
import 'package:fitness/ui/features/fitness/view_models/fitness_view_model.dart';
import 'package:fitness/ui/features/fitness/views/saved_program.dart';
import 'package:fitness/ui/features/profile/view_models/profile_view_model.dart';
import 'package:fitness/ui/features/profile/views/adjust_workout_plan_page.dart';
import 'package:fitness/ui/features/profile/views/billing_page.dart';
import 'package:fitness/ui/features/profile/views/feature_request_page.dart';
import 'package:fitness/ui/features/profile/views/language_settings_page.dart';
import 'package:fitness/ui/features/profile/views/legal_document_page.dart';
import 'package:fitness/ui/features/profile/views/personal_details.dart';
import 'package:fitness/ui/features/profile/views/profile_dialogs.dart';
import 'package:fitness/ui/features/profile/views/support_contact_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF0A0C12);
const _kCard    = Color(0xFF111318);
const _kBorder  = Color(0xFF1E2330);
const _kLime    = Color(0xFFCCFF00);
const _kDim     = Color(0x80FFFFFF);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<ProfileViewModel>()..loadProfile()),
        ChangeNotifierProvider(create: (_) => di.sl<FitnessViewModel>()..loadFitnessPlans()),
      ],
      child: Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _ProfileHero()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionLabel(label: t.sectionYourWorkoutsData),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _SavedDataCard(),
            )),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionLabel(label: t.sectionGeneral),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SettingsGroup(items: _generalItems(t)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionLabel(label: t.sectionLegalSupport),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SettingsGroup(items: _legalItems(t)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionLabel(label: t.sectionAccount),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SettingsGroup(items: _accountItems(t)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                child: Center(
                  child: Text(
                    'VERSION 1.0.177',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.25),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Consumer<ProfileViewModel>(
      builder: (_, vm, __) {
        final profile = vm.profile;
        final name    = profile?.name ?? profile?.email ?? 'Athlete';
        final initial = profile?.initial ?? '?';
        final goal    = profile?.goal;
        final height  = profile?.height;
        final weight  = profile?.weight;
        final days    = profile?.workoutDays;

        return Container(
          decoration: BoxDecoration(
            color: _kCard,
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // top row: title + edit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.profileTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PersonalDetailsPage()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kLime.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _kLime.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 13, color: _kLime),
                              const SizedBox(width: 5),
                              Text(
                                t.editAction,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kLime,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // avatar + name
                  Row(
                    children: [
                      // avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A9A8F), Color(0xFF0D6B62)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A9A8F).withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: vm.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  initial,
                                  style: GoogleFonts.poppins(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            if (profile?.email != null && profile?.name != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                profile!.email!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _kDim,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (goal != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _kLime.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _kLime.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  goal,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _kLime,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // stats row
                  if (height != null || weight != null || days != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Row(
                        children: [
                          if (height != null)
                            _StatPill(label: 'Height', value: height),
                          if (height != null && (weight != null || days != null))
                            _StatDivider(),
                          if (weight != null)
                            _StatPill(label: 'Weight', value: weight),
                          if (weight != null && days != null)
                            _StatDivider(),
                          if (days != null)
                            _StatPill(label: 'Days/week', value: '$days'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: _kDim),
            ),
          ],
        ),
      );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        color: _kBorder,
      );
}

// ── Saved data card ───────────────────────────────────────────────────────────

class _SavedDataCard extends StatelessWidget {
  const _SavedDataCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final fitnessVm = context.read<FitnessViewModel>();
    final savedPath = fitnessVm.plans.isNotEmpty ? fitnessVm.plans.first.imagePath : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: fitnessVm,
            child: const SavedProgramPage(),
          ),
        ),
      ),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // image panel
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 110,
                height: double.infinity,
                child: savedPath != null
                    ? FutureBuilder<bool>(
                        future: File(savedPath).exists(),
                        builder: (_, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return _ImagePlaceholder();
                          }
                          return snap.data == true
                              ? Image.file(File(savedPath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _ImagePlaceholder())
                              : _ImagePlaceholder();
                        },
                      )
                    : _ImagePlaceholder(),
              ),
            ),
            // text + cta
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t.savedWorkoutsTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.savedWorkoutsSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.4,
                        color: _kDim,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded,
                              color: Colors.white.withValues(alpha: 0.6), size: 13),
                          const SizedBox(width: 5),
                          Text(
                            t.viewAllAction,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white.withValues(alpha: 0.05),
        child: Center(
          child: Icon(
            Icons.folder_copy_outlined,
            color: Colors.white.withValues(alpha: 0.2),
            size: 36,
          ),
        ),
      );
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 3,
            height: 15,
            decoration: BoxDecoration(
              color: _kLime,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ],
      );
}

// ── Settings group ────────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final List<_Item> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return _SettingsRow(item: item, isFirst: i == 0, isLast: i == items.length - 1);
        }),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final _Item item;
  final bool isFirst;
  final bool isLast;
  const _SettingsRow({required this.item, required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: item.onTap != null ? () => item.onTap!(context) : null,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isFirst ? 18 : 0),
            bottom: Radius.circular(isLast ? 18 : 0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.iconBg ?? Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor ?? Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: item.destructive
                          ? const Color(0xFFFF5B5B)
                          : Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.25),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            indent: 68,
            color: _kBorder,
          ),
      ],
    );
  }
}

class _Item {
  final IconData icon;
  final String title;
  final Function(BuildContext)? onTap;
  final Color? iconColor;
  final Color? iconBg;
  final bool destructive;

  _Item({
    required this.icon,
    required this.title,
    this.onTap,
    this.iconColor,
    this.iconBg,
    this.destructive = false,
  });
}

List<_Item> _generalItems(AppLocalizations t) => [
  _Item(
    icon: Icons.person_outline_rounded,
    title: t.menuPersonalDetails,
    onTap: (ctx) => Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const PersonalDetailsPage()),
    ),
  ),
  _Item(
    icon: Icons.fitness_center_rounded,
    title: t.menuAdjustWorkoutPlan,
    onTap: (ctx) => Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const AdjustWorkoutPlanPage()),
    ),
  ),
  _Item(
    icon: Icons.credit_card_rounded,
    title: t.menuBilling,
    onTap: (ctx) => Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const BillingPage()),
    ),
  ),
  _Item(
    icon: Icons.language_rounded,
    title: t.menuLanguage,
    onTap: (ctx) => Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const LanguageSettingsPage()),
    ),
  ),
];

List<_Item> _legalItems(AppLocalizations t) => [
  _Item(
    icon: Icons.description_outlined,
    title: t.menuTermsAndConditions,
    onTap: (ctx) => Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
    ),
  ),
  _Item(
    icon: Icons.privacy_tip_outlined,
    title: t.menuPrivacyPolicy,
    onTap: (ctx) => Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
    ),
  ),
  _Item(
    icon: Icons.email_outlined,
    title: t.menuSupportEmail,
    onTap: (ctx) => Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const SupportContactPage()),
    ),
  ),
  _Item(
    icon: Icons.campaign_outlined,
    title: t.menuFeatureRequest,
    onTap: (ctx) => Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const FeatureRequestPage()),
    ),
  ),
];

List<_Item> _accountItems(AppLocalizations t) => [
  _Item(
    icon: Icons.logout_rounded,
    title: t.menuLogout,
    iconColor: Colors.white,
    onTap: (ctx) => handleLogout(ctx),
  ),
  _Item(
    icon: Icons.person_remove_outlined,
    title: t.menuDeleteAccount,
    iconColor: const Color(0xFFFF5B5B),
    iconBg: const Color(0xFFFF5B5B).withValues(alpha: 0.12),
    destructive: true,
    onTap: (ctx) => showDeleteAccountDialog(ctx),
  ),
];
