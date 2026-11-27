import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fitness/ui/core/constants/assets.dart';
import 'package:fitness/ui/core/utils/audio_player_service.dart';
import 'package:flutter/services.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/theme/app_pallet.dart';
import 'package:fitness/ui/core/widgets/greeting.dart';
import 'package:fitness/ui/features/fitness/views/saved_workouts_card.dart';
import 'package:fitness/ui/features/progression/views/progression_entry_section.dart';
import 'package:fitness/data/models/body/scan_mapper.dart';
import 'package:fitness/data/repositories/body_tracking_repository.dart';
import 'package:fitness/ui/features/analytic/view_models/analytics_view_model.dart';
import 'package:fitness/ui/features/muscle_map/views/muscle_map_card.dart';
import 'package:fitness/ui/features/fitness/view_models/fitness_view_model.dart';
import 'package:fitness/ui/features/fitness/views/motivation_schedule_sheet.dart';
import 'package:fitness/ui/features/fitness/view_models/motivation_view_model.dart';
import 'package:fitness/data/services/motivation/motivation_notification_service.dart';
import 'package:fitness/ui/features/fitness/views/streak_sheet.dart';
import 'package:fitness/ui/features/fitness/views/workout_modal.dart';
import 'package:fitness/data/services/fitness/body_composition_service.dart';
import 'package:fitness/data/services/fitness/body_scan_storage.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/ui/features/fitness/views/body_composition_result_page.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitness/data/services/billing/paywall_service.dart';
import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:fitness/data/services/billing/trial_reminder_storage.dart';
import 'package:fitness/ui/features/fitness/views/trial_ending_dialog.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kLime     = Color(0xFFCCFF00);
const _kLimeDim  = Color(0x26CCFF00);
const _kCard     = Color(0xFF111318);
const _kBorder   = Color(0xFF1E2330);
const _kDimWhite = Color(0x80FFFFFF);

class FitnessHomePage extends StatefulWidget {
  const FitnessHomePage({super.key});

  @override
  State<FitnessHomePage> createState() => _FitnessHomePageState();
}

class _FitnessHomePageState extends State<FitnessHomePage> {
  Timer?  _greetingTimer;
  String  _greeting = GreetingHelper.getGreeting();
  String  _emoji    = GreetingHelper.getGreetingEmoji();

  DateTime           _selectedDate    = DateTime.now();

  final _motivationVm = sl<MotivationViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FitnessViewModel>().loadFitnessPlans();
      _motivationVm.load();
      _maybeRemindTrialEnding();
    });
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _greeting = GreetingHelper.getGreeting();
          _emoji    = GreetingHelper.getGreetingEmoji();
        });
      }
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  String _shortName(String name, {int max = 15}) =>
      name.length <= max ? name : '${name.substring(0, max)}…';

  /// Warn once, two days out, that the free trial is about to be charged.
  ///
  /// On the home screen rather than as a notification: it needs no permission
  /// the user may have refused, and this is the screen they open anyway. The
  /// decision of whether to show lives in TrialReminderStorage so it can be
  /// tested without a widget.
  Future<void> _maybeRemindTrialEnding() async {
    final access = sl<AccessPolicy>();
    final subs = sl<SubscriptionService>();
    final endsAt = access.periodEndsAt;

    final last = await TrialReminderStorage.lastRemindedFor();
    if (!TrialReminderStorage.shouldRemind(
      trialEndingSoon: access.trialEndingSoon,
      willRenew: subs.willRenew,
      endsAt: endsAt,
      lastRemindedFor: last,
    )) {
      return;
    }
    if (!mounted) return;

    // Recorded before showing: a reminder that reappears because the dialog
    // was dismissed the wrong way is more annoying than one that is missed,
    // and Profile → Billing says the same thing at any time.
    await TrialReminderStorage.markShown(endsAt!);
    if (!mounted) return;

    await TrialEndingDialog.show(
      context,
      daysLeft: access.daysRemaining ?? 0,
      endsAt: endsAt,
      price: subs.activePriceString,
      onManage: () => sl<PaywallService>().presentCustomerCenter(),
    );
  }

  /// One event for every card on the home screen, so "which cards do people
  /// reach for, and how many hit the paywall" is a single breakdown. [feature]
  /// is the premium feature the card opens, if any.
  void _trackCard(String card, {PremiumFeature? feature}) {
    Analytics.track(AnalyticsEvents.homeCardTapped, {
      'card': card,
      'locked': feature != null && !sl<AccessPolicy>().canUse(feature),
    });
  }

  Future<void> _scanFoodItem() async {
    // Gate before the camera opens, not after — asking someone to photograph
    // their lunch and then telling them to pay is a worse experience than
    // being told up front.
    if (!sl<AccessPolicy>().canUse(PremiumFeature.nutritionScanner)) {
      await requirePremium(
          context, PremiumFeature.nutritionScanner, _scanFoodItem);
      return;
    }
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        Analytics.track(AnalyticsEvents.scanPhotoSelected,
            {'kind': 'meal', 'source': 'camera'});
        context.push('/nutrition', extra: {'imagePath': image.path});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Camera error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  String? _bodyScanImagePath;

  Future<void> _pickBodyScanImage(ImageSource source) async {
    if (!sl<AccessPolicy>().canUse(PremiumFeature.bodyComposition)) {
      await requirePremium(context, PremiumFeature.bodyComposition,
          () => _pickBodyScanImage(source));
      return;
    }
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1280,
      );
      if (image == null || !mounted) return;
      Analytics.track(AnalyticsEvents.scanPhotoSelected,
          {'kind': 'body', 'source': source.name});
      setState(() => _bodyScanImagePath = image.path);
      _runBodyComposition(image.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _runBodyComposition(String imagePath) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AnalysingOverlay(),
    );
    try {
      final result = await BodyCompositionService().analyse(
        image: File(imagePath),
      );
      await BodyScanStorage().save(result, imagePath);
      // Keep the headline numbers on the server too, for the advice. Best effort.
      unawaited(sl<BodyTrackingRepository>().recordScan(ScanMapper.toApi(
        result,
        weightKg: sl<AnalyticsViewModel>().latestWeight?.weightKg,
      )));
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BodyCompositionResultPage(
          result: result,
          imagePath: imagePath,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Analysis failed: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _openStreakSheet(int streak) {
    _trackCard('streak');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StreakSheet(streak: streak),
    );
  }


  /// Debug-only: verify notifications actually reach the tray.
  Future<void> _sendTestNotification() async {
    final ok = await sl<MotivationNotificationService>()
        .sendTestNotification(seconds: 10);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        ok
            ? 'Test notification scheduled — background the app, it lands in 10s.'
            : 'Notifications are blocked. Enable them in Settings.',
        style: GoogleFonts.inter(fontSize: 13),
      ),
      backgroundColor: ok ? const Color(0xFF1A2A00) : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _openTonePicker() {
    if (!sl<AccessPolicy>().canUse(PremiumFeature.motivation)) {
      requirePremium(context, PremiumFeature.motivation, _openTonePicker);
      return;
    }
    String? gender;
    try {
      gender = sl<SupabaseClient>().auth.currentUser?.userMetadata?['gender'] as String?;
    } catch (_) {}

    final userGender =
        (gender?.toLowerCase() == 'female' || gender?.toLowerCase() == 'f')
            ? 'female'
            : 'male';
    final toneList = List<String>.from(Constant.toneOptions.first[userGender] ?? []);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _TonePickerSheet(
        tones: toneList,
        vm: _motivationVm,
        // Step 2: pick when the daily AI notification should arrive. Reading a
        // message now happens inside the sheet, so this is the only path that
        // still leaves it.
        onScheduleDaily: (tone) {
          Navigator.of(sheetCtx).pop();
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => MotivationScheduleSheet(
              tone: tone,
              vm: _motivationVm,
            ),
          );
        },
      ),
    );
  }

  void _showWorkoutCompletedAlert(DateTime date) {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppPalete.backgroundColorBk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
            const SizedBox(width: 8),
            Text(
              'Workout Completed',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPalete.whiteColor),
            ),
          ],
        ),
        content: Text(
          'You already completed the workout for $dateStr. Great job!',
          style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppPalete.whiteColor.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _kLime)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fitnessVm = context.watch<FitnessViewModel>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeHeader(
              streak: fitnessVm.streak,
              onStreakTap: () => _openStreakSheet(fitnessVm.streak),
            ),
            const SizedBox(height: 14),
            _GreetingLine(
              greeting: _greeting,
              emoji: _emoji,
              displayName: _shortName(
                sl<GetCurrentUser>()()?.name ??
                    sl<GetCurrentUser>()()?.email ??
                    'User',
              ),
            ),
            _CollapsibleDateStrip(
              selectedDate: _selectedDate,
              workoutMappings: fitnessVm.workoutMappings,
              completedDates: fitnessVm.completedDates,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
                context.read<FitnessViewModel>().selectDate(date);
              },
              onCompletedDateTapped: _showWorkoutCompletedAlert,
            ),
            // ── Redesigned scroll content ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── Food Scan ────────────────────────────────────────────
                    _SectionLabel(label: 'Nutrition Scanner'),
                    const SizedBox(height: 12),
                    _FoodScanCard(onTap: () {
                      _trackCard('nutrition_scanner',
                          feature: PremiumFeature.nutritionScanner);
                      _scanFoodItem();
                    }),

                    const SizedBox(height: 28),

                    // ── Body Composition Scan ────────────────────────────────
                    _SectionLabel(label: 'Body Composition'),
                    const SizedBox(height: 12),
                    _BodyScanCard(
                      imagePath: _bodyScanImagePath,
                      onCamera: () {
                        _trackCard('body_composition',
                            feature: PremiumFeature.bodyComposition);
                        _pickBodyScanImage(ImageSource.camera);
                      },
                      onGallery: () {
                        _trackCard('body_composition',
                            feature: PremiumFeature.bodyComposition);
                        _pickBodyScanImage(ImageSource.gallery);
                      },
                      onClear:   () => setState(() => _bodyScanImagePath = null),
                    ),

                    const SizedBox(height: 28),

                    // ── Motivation ───────────────────────────────────────────
                    _SectionLabel(label: 'Your Motivation'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        _trackCard('motivation',
                            feature: PremiumFeature.motivation);
                        _openTonePicker();
                      },
                      // Debug builds: long-press to fire a test notification
                      // 10s out and confirm OS delivery on a real device.
                      onLongPress: kDebugMode ? _sendTestNotification : null,
                      child: _MotivationBanner(),
                    ),

                    const SizedBox(height: 28),

                    // ── Muscle map ───────────────────────────────────────────
                    // The cards below carry their own titles, so no label here.
                    const MuscleMapCard(),

                    const SizedBox(height: 28),

                    // ── Workout program ──────────────────────────────────────
                    const SavedWorkoutsCard(),

                    // Only when an update is waiting; the programs screen
                    // always shows where updates stand.
                    const ProgressionEntrySection(onlyWhenReady: true),

                    const SizedBox(height: 110),
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

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _kLime,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ── Food scan card ────────────────────────────────────────────────────────────

class _FoodScanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _FoodScanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.17,
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
            // Image panel
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.30,
                height: double.infinity,
                child: Image.asset(ImagePath.foodScan, fit: BoxFit.cover),
              ),
            ),
            // Text + CTA
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Food Item',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Get instant nutritional info\nfor anything on your plate.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.5,
                            color: _kDimWhite,
                          ),
                        ),
                      ],
                    ),
                    // Tap badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kLime.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kLime.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_rounded,
                              color: _kLime, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            'Tap to scan',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kLime,
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

// ── Body composition scan card ────────────────────────────────────────────────

class _BodyScanCard extends StatelessWidget {
  final String?    imagePath;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onClear;

  const _BodyScanCard({
    required this.onCamera,
    required this.onGallery,
    required this.onClear,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasImage ? _kLime.withValues(alpha: 0.35) : _kBorder),
        boxShadow: [
          BoxShadow(
            color: hasImage
                ? _kLime.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: icon + title + NEW badge ─────────────────────────
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _kLime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kLime.withValues(alpha: 0.25)),
                ),
                child: const Icon(
                  Icons.accessibility_new_rounded,
                  color: _kLime, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Body Composition Scan',
                      style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white, height: 1.2)),
                    const SizedBox(height: 3),
                    Text('AI-powered body analysis',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: _kDimWhite)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A00),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kLime.withValues(alpha: 0.3)),
                ),
                child: Text('NEW',
                  style: GoogleFonts.poppins(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: _kLime, letterSpacing: 0.8)),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Stat pills ─────────────────────────────────────────────────
          const Row(
            children: [
              _StatPill(icon: Icons.water_drop_outlined,    label: 'Body Fat %'),
              SizedBox(width: 8),
              _StatPill(icon: Icons.fitness_center_rounded,  label: 'Muscle Mass'),
              SizedBox(width: 8),
              _StatPill(icon: Icons.monitor_weight_outlined, label: 'BMI'),
            ],
          ),

          const SizedBox(height: 18),

          // ── Image preview (shown after pick) ──────────────────────────
          if (hasImage) ...[
            _BodyScanPreview(path: imagePath!, onClear: onClear),
            const SizedBox(height: 14),
          ],

          // ── Action buttons ─────────────────────────────────────────────
          Row(
            children: [
              // Camera button (lime fill)
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: onCamera,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _kLime,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _kLime.withValues(alpha: 0.25),
                          blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_rounded,
                            color: Colors.black, size: 17),
                        const SizedBox(width: 7),
                        Text(hasImage ? 'Retake' : 'Camera',
                          style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Colors.black)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Upload button (outlined)
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: onGallery,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBorder, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 17),
                        const SizedBox(width: 7),
                        Text('Upload',
                          style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Body scan image preview ───────────────────────────────────────────────────

class _BodyScanPreview extends StatelessWidget {
  final String path;
  final VoidCallback onClear;
  const _BodyScanPreview({required this.path, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            File(path),
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
        // Gradient scrim at bottom
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Label
        Positioned(
          left: 14, bottom: 12,
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: _kLime, size: 14),
              const SizedBox(width: 5),
              Text('Image ready for analysis',
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.white)),
            ],
          ),
        ),
        // Remove ×
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2), width: 1),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kLime, size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Motivation banner ─────────────────────────────────────────────────────────

class _MotivationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      decoration: BoxDecoration(
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
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Image.asset(
                ImagePath.motivateBanner,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // Overlay gradient
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Label
          Positioned(
            left: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [ 
                Text(
                  'Tap to choose your vibe',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Play icon
        ],
      ),
    );
  }
}

// ─── Tone picker sheet ────────────────────────────────────────────────────────

/// Tone chooser for the motivation feature. Replaces the old stock Material
/// dialog, which rendered on a light Card with black text and clashed with
/// the rest of the dark app.
/// Tone picker for the motivation feature.
///
/// "Motivate me now" writes a message in the chosen tone from the user's own
/// profile — goal, body stats, streak and recent training, all assembled
/// server-side — and renders it in place. It deliberately does not navigate:
/// the message is short, and pushing a route to show one paragraph loses the
/// tone list the user may want to try again with.
class _TonePickerSheet extends StatefulWidget {
  final List<String> tones;
  final MotivationViewModel vm;
  final ValueChanged<String> onScheduleDaily;

  const _TonePickerSheet({
    required this.tones,
    required this.vm,
    required this.onScheduleDaily,
  });

  @override
  State<_TonePickerSheet> createState() => _TonePickerSheetState();
}

class _TonePickerSheetState extends State<_TonePickerSheet> {
  String? _selected;
  bool _generating = false;

  /// Generate in the selected tone, then present it in a dialog.
  ///
  /// The sheet stays put underneath while the request runs — only the button
  /// shows progress — so the layout never reflows mid-generation.
  Future<void> _motivateNow() async {
    final tone = _selected;
    if (tone == null || _generating) return;

    setState(() => _generating = true);

    final message = await widget.vm.motivateNow(
      tone.toLowerCase().replaceAll(' ', '-'),
    );
    if (!mounted) return;
    setState(() => _generating = false);
    Analytics.track(AnalyticsEvents.motivationGenerated,
        {'tone': tone, 'success': message != null});

    if (message == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Couldn't reach your coach — try again shortly.",
            style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Chime as the message lands, the way a delivered message announces
    // itself. Not awaited — the dialog should not wait on audio.
    unawaited(AudioPlayerService.playAsset(SoundPath.messageBell));
    HapticFeedback.mediumImpact();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogCtx) => _MotivationDialog(
        message: message,
        tone: tone,
        onAnother: () {
          Navigator.of(dialogCtx).pop();
          _motivateNow();
        },
      ),
    );
  }

  void _select(String tone) => setState(() => _selected = tone);

  /// Icon per tone, matched on keyword so the female/male lists — and any
  /// tone added later — all resolve to something sensible.
  static IconData _iconFor(String tone) {
    final t = tone.toLowerCase();
    if (t.contains('alpha') || t.contains('dominant')) return Icons.bolt_rounded;
    if (t.contains('calm') || t.contains('disciplin')) {
      return Icons.self_improvement_rounded;
    }
    if (t.contains('warrior')) return Icons.shield_rounded;
    if (t.contains('coach')) return Icons.sports_rounded;
    if (t.contains('hype') || t.contains('energy')) {
      return Icons.local_fire_department_rounded;
    }
    if (t.contains('confident') || t.contains('empower')) {
      return Icons.auto_awesome_rounded;
    }
    if (t.contains('soft') || t.contains('encourag')) {
      return Icons.favorite_rounded;
    }
    if (t.contains('self-care') || t.contains('care')) return Icons.spa_rounded;
    if (t.contains('goal')) return Icons.flag_rounded;
    return Icons.graphic_eq_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final canMotivate = _selected != null;
    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // grab handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _kLime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: _kLime, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pick your tone',
                          style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('How should your coach speak to you?',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: _kDimWhite)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white54, size: 16),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              if (widget.tones.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text('No tone options available',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: _kDimWhite)),
                  ),
                )
              else
                // Constrained so a long tone list scrolls instead of
                // overflowing the sheet on small screens.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        for (final tone in widget.tones)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ToneOption(
                              label: tone,
                              icon: _iconFor(tone),
                              isSelected: _selected == tone,
                              onTap: () => _select(tone),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // CTA — visibly inert until a tone is chosen, rather than
              // firing a "please select" snackbar like the old dialog.
              GestureDetector(
                onTap: canMotivate && !_generating ? _motivateNow : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: canMotivate && !_generating
                        ? _kLime
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: canMotivate && !_generating
                        ? [BoxShadow(
                            color: _kLime.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6))]
                        : null,
                  ),
                  child: Center(
                    child: _generating
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kLime),
                          )
                        : Text(
                            canMotivate ? 'Motivate me now' : 'Select a tone',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: canMotivate ? Colors.black : _kDimWhite,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Secondary path: schedule a daily AI notification in this tone
              // instead of reading one right now.
              GestureDetector(
                onTap: canMotivate && !_generating
                    ? () => widget.onScheduleDaily(_selected!)
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: canMotivate
                          ? _kLime.withValues(alpha: 0.35)
                          : _kBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_active_rounded,
                          size: 15,
                          color: canMotivate ? _kLime : _kDimWhite),
                      const SizedBox(width: 7),
                      Text('Remind me daily',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: canMotivate ? _kLime : _kDimWhite,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The generated motivation, rendered inside the tone sheet.
///
/// Covers all three states the request can be in — writing, written, failed —
/// so the sheet never shows a blank gap where the message should be.
/// The generated motivation, presented as a focused dialog.
///
/// A dialog rather than inline copy in the sheet: the message is the payoff of
/// the whole flow, and dropping it into the tone list made the sheet reflow
/// around it. Here it arrives over a dimmed backdrop with nothing competing.
class _MotivationDialog extends StatelessWidget {
  final MotivationMessage message;
  final String tone;
  final VoidCallback onAnother;

  const _MotivationDialog({
    required this.message,
    required this.tone,
    required this.onAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kLime.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: _kLime.withValues(alpha: 0.12),
              blurRadius: 34,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _kLime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.notifications_active_rounded,
                    color: _kLime, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(tone,
                    style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: _kLime)),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 15),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Text(message.title,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 10),
            Text(message.body,
                style: GoogleFonts.inter(
                    fontSize: 14.5,
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.82))),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: onAnother,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _kLime.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text('Another',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kLime)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: _kLime,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text("Let's go",
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
class _ToneOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToneOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? _kLime.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _kLime.withValues(alpha: 0.5) : _kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon,
              size: 18, color: isSelected ? _kLime : Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _kLime : Colors.white,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isSelected
                ? const Icon(Icons.check_circle_rounded,
                    key: ValueKey('on'), color: _kLime, size: 20)
                : Icon(Icons.circle_outlined,
                    key: const ValueKey('off'),
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 20),
          ),
        ]),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final int streak;
  final VoidCallback onStreakTap;
  const _HomeHeader({required this.streak, required this.onStreakTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 70, height: 70,
          child: Image.asset(ImagePath.appLogo),
        ),
        _StreakBadge(streak: streak, onTap: onStreakTap),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  final VoidCallback onTap;
  const _StreakBadge({required this.streak, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = streak > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active
                ? _kLime.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: active
              ? [BoxShadow(
                  color: _kLime.withValues(alpha: 0.18),
                  blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? _kLimeDim : Colors.white.withValues(alpha: 0.06),
              ),
              child: Icon(Icons.local_fire_department_rounded,
                  size: 15, color: active ? _kLime : Colors.white38),
            ),
            const SizedBox(width: 8),
            Text(
              '$streak',
              style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: active ? _kLime : Colors.white38),
            ),
            const SizedBox(width: 4),
            Text(
              streak == 1 ? 'day' : 'days',
              style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.35)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Greeting ─────────────────────────────────────────────────────────────────

class _GreetingLine extends StatelessWidget {
  final String greeting;
  final String emoji;
  final String displayName;
  const _GreetingLine({
    required this.greeting,
    required this.emoji,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            '$greeting ',
            style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
          ),
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            displayName,
            style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─── Week card / full-month calendar ──────────────────────────────────────────
//
// One card: a "This week" header with the session count, then seven day
// circles. Completed days are a lime disc with a check, days with a planned
// workout are a lime ring with a dot (it breathes to invite the tap), the rest
// are a quiet disc holding the date. The header toggles the full month view.

const _kChip  = Color(0xFF1B2030);
const _kInk   = Color(0xFF0A0C12);
const _kMuted = Color(0xFF8C909B);

class _CollapsibleDateStrip extends StatefulWidget {
  final DateTime selectedDate;
  final Map<DateTime, dynamic> workoutMappings;
  final Set<DateTime> completedDates;
  final void Function(DateTime) onDateSelected;
  final void Function(DateTime) onCompletedDateTapped;

  const _CollapsibleDateStrip({
    required this.selectedDate,
    required this.workoutMappings,
    required this.completedDates,
    required this.onDateSelected,
    required this.onCompletedDateTapped,
  });

  @override
  State<_CollapsibleDateStrip> createState() => _CollapsibleDateStripState();
}

class _CollapsibleDateStripState extends State<_CollapsibleDateStrip> {
  bool _expanded = false;
  late DateTime _viewMonth;

  static const _kWeekDays   = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _kMonthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  @override
  void didUpdateWidget(_CollapsibleDateStrip old) {
    super.didUpdateWidget(old);
    if (!_expanded) return;
    final sel = widget.selectedDate;
    if (sel.year != _viewMonth.year || sel.month != _viewMonth.month) {
      setState(() => _viewMonth = DateTime(sel.year, sel.month));
    }
  }

  void _toggleExpanded() => setState(() => _expanded = !_expanded);
  void _prevMonth() => setState(() =>
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));
  void _nextMonth() => setState(() =>
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));

  void _handleDateTap(DateTime date) {
    final norm = DateTime(date.year, date.month, date.day);
    widget.onDateSelected(date);
    if (widget.completedDates.contains(norm)) {
      widget.onCompletedDateTapped(date);
      return;
    }
    final mapping = widget.workoutMappings[norm];
    if (mapping?.workoutDay != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, __) =>
              WorkoutModal(workoutDay: mapping!.workoutDay!, date: date),
        ),
      );
    }
  }

  bool _isSelected(DateTime d) =>
      d.day == widget.selectedDate.day &&
      d.month == widget.selectedDate.month &&
      d.year == widget.selectedDate.year;

  bool _isToday(DateTime d) {
    final t = DateTime.now();
    return d.day == t.day && d.month == t.month && d.year == t.year;
  }

  List<DateTime> _weekDates() {
    final today = DateTime.now();
    return List.generate(7, (i) => today.add(Duration(days: i)));
  }

  List<DateTime?> _calendarDays() {
    final first          = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final leadingBlanks  = (first.weekday - 1) % 7;
    final daysInMonth    = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    return List.generate(42, (i) {
      final dayNum = i - leadingBlanks + 1;
      if (dayNum < 1 || dayNum > daysInMonth) return null;
      return DateTime(_viewMonth.year, _viewMonth.month, dayNum);
    });
  }

  /// "3 of 4 sessions" for the dates on show: done out of planned.
  String _summary(Iterable<DateTime> dates) {
    var planned = 0;
    var done = 0;
    for (final d in dates) {
      final norm = DateTime(d.year, d.month, d.day);
      if (widget.completedDates.contains(norm)) {
        done++;
        planned++;
      } else if (widget.workoutMappings.containsKey(norm)) {
        planned++;
      }
    }
    if (planned == 0) return 'No sessions planned';
    return '$done of $planned ${planned == 1 ? 'session' : 'sessions'}';
  }

  Widget _buildHeader() {
    final summary = _summary(
        _expanded ? _calendarDays().whereType<DateTime>() : _weekDates());
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: _expanded ? 'Show this week' : 'Show month calendar',
      value: summary,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleExpanded,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _expanded ? 'Calendar' : 'This week',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              Text(
                summary,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w500, color: _kMuted),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                duration: const Duration(milliseconds: 220),
                turns: _expanded ? 0.5 : 0.0,
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: _kMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeek() {
    return Row(
      children: [
        for (final date in _weekDates())
          Expanded(
            child: _WeekDayCell(
              date: date,
              isSelected: _isSelected(date),
              isToday: _isToday(date),
              hasWorkout: widget.workoutMappings
                  .containsKey(DateTime(date.year, date.month, date.day)),
              isCompleted: widget.completedDates
                  .contains(DateTime(date.year, date.month, date.day)),
              onTap: () => _handleDateTap(date),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendar() {
    final days = _calendarDays();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _NavArrow(
                  icon: Icons.chevron_left_rounded,
                  label: 'Previous month',
                  onTap: _prevMonth),
              Expanded(
                child: Text(
                  '${_kMonthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  label: 'Next month',
                  onTap: _nextMonth),
            ],
          ),
        ),
        Row(
          children: _kWeekDays.map((d) => Expanded(
            child: Center(
              child: Text(d,
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _kMuted)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 2,
            childAspectRatio: 1.1,
          ),
          itemCount: days.length,
          itemBuilder: (_, i) {
            final date = days[i];
            if (date == null) return const SizedBox.shrink();
            final norm = DateTime(date.year, date.month, date.day);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleDateTap(date),
              child: _CalendarCell(
                date: date,
                isSelected: _isSelected(date),
                isToday: _isToday(date),
                hasWorkout: widget.workoutMappings.containsKey(norm),
                isCompleted: widget.completedDates.contains(norm),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LegendDot(filled: false, label: 'Training'),
            SizedBox(width: 20),
            _LegendDot(filled: true, label: 'Completed'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded ? _buildCalendar() : _buildWeek(),
          ),
        ],
      ),
    );
  }
}

// ─── Week day cell ────────────────────────────────────────────────────────────

class _WeekDayCell extends StatefulWidget {
  final DateTime date;
  final bool isSelected, isToday, hasWorkout, isCompleted;
  final VoidCallback onTap;
  const _WeekDayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasWorkout,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  State<_WeekDayCell> createState() => _WeekDayCellState();
}

class _WeekDayCellState extends State<_WeekDayCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _names   = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  /// A planned workout that is not done yet: tapping it opens the workout
  /// sheet, so its ring breathes to invite the tap.
  bool get _isStartable => widget.hasWorkout && !widget.isCompleted;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (_isStartable) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _WeekDayCell old) {
    super.didUpdateWidget(old);
    // The strip is rebuilt every day, so keep the animation in step with
    // whatever date and state this cell now shows.
    if (_isStartable && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_isStartable && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _disc(double size, double t) {
    final Widget disc;
    if (widget.isCompleted) {
      disc = Container(
        width: size, height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _kLime),
        child: Icon(Icons.check_rounded, size: size * 0.56, color: _kInk),
      );
    } else if (_isStartable) {
      disc = Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: _kLime.withValues(alpha: 0.65 + 0.35 * t), width: 2),
          boxShadow: [
            BoxShadow(
              color: _kLime.withValues(alpha: 0.08 + 0.22 * t),
              blurRadius: 6 + 8 * t,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _kLime),
          ),
        ),
      );
    } else {
      disc = Container(
        width: size, height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _kChip),
        child: Text(
          '${widget.date.day}',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.isSelected || widget.isToday ? Colors.white : _kMuted,
          ),
        ),
      );
    }
    // Selection is a thin lime ring around whichever disc is showing.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.isSelected
              ? _kLime.withValues(alpha: 0.55)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: disc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.isCompleted
        ? ', workout completed'
        : widget.hasWorkout
            ? ', workout planned'
            : '';
    return Semantics(
      button: true,
      selected: widget.isSelected,
      excludeSemantics: true,
      label: '${_names[widget.date.weekday - 1]} ${widget.date.day}$status',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: LayoutBuilder(
            builder: (context, c) {
              final size = (c.maxWidth - 10).clamp(24.0, 32.0);
              return AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final t = _isStartable
                      ? Curves.easeInOut.transform(_pulse.value)
                      : 0.0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _letters[widget.date.weekday - 1],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.isSelected
                              ? _kLime
                              : widget.isToday
                                  ? Colors.white
                                  : _kMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _disc(size, t),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Calendar cell ────────────────────────────────────────────────────────────

class _CalendarCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected, isToday, hasWorkout, isCompleted;
  const _CalendarCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasWorkout,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final startable = hasWorkout && !isCompleted;
    final Color border = isSelected
        ? (isCompleted
            ? Colors.white.withValues(alpha: 0.6)
            : _kLime.withValues(alpha: 0.7))
        : startable
            ? _kLime
            : Colors.transparent;
    return LayoutBuilder(
      builder: (context, c) {
        final size = (c.maxHeight < c.maxWidth ? c.maxHeight : c.maxWidth) - 2;
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: size, height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? _kLime
                  : isSelected
                      ? _kLime.withValues(alpha: 0.12)
                      : isToday
                          ? _kChip
                          : Colors.transparent,
              border: Border.all(
                  color: border, width: isSelected || startable ? 1.5 : 1),
            ),
            child: Text(
              '${date.day}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected || isToday || isCompleted
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isCompleted
                    ? _kInk
                    : startable
                        ? _kLime
                        : isSelected || isToday
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44, height: 44,
        child: Center(
          child: Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _kChip),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
        ),
      ),
    ),
  );
}

/// Legend swatch that matches the cells: a ring for training, a disc for done.
class _LegendDot extends StatelessWidget {
  final bool filled;
  final String label;
  const _LegendDot({required this.filled, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? _kLime : Colors.transparent,
          border: filled ? null : Border.all(color: _kLime, width: 1.5),
        ),
      ),
      const SizedBox(width: 6),
      Text(label,
        style: GoogleFonts.inter(fontSize: 11, color: _kMuted)),
    ],
  );
}

// ── Analysing overlay ─────────────────────────────────────────────────────────

class _AnalysingOverlay extends StatelessWidget {
  const _AnalysingOverlay();

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF111318),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1E2330)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCCFF00)),
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 20),
          Text('Analysing your physique…', style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
          )),
          const SizedBox(height: 6),
          Text('This takes 30–60 seconds', style: GoogleFonts.inter(
            fontSize: 12, color: Colors.white.withValues(alpha: 0.4),
          )),
        ]),
      ),
    ),
  );
}
