import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fitness/ui/core/constants/assets.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/theme/app_pallet.dart';
import 'package:fitness/ui/core/widgets/app_widget.dart';
import 'package:fitness/ui/core/widgets/greeting.dart';
import 'package:fitness/domain/models/workout_day_mapping.dart';
import 'package:fitness/ui/features/fitness/view_models/fitness_view_model.dart';
import 'package:fitness/ui/features/fitness/views/motivate_page.dart';
import 'package:fitness/ui/features/fitness/views/streak_sheet.dart';
import 'package:fitness/ui/features/fitness/views/workout_modal.dart';
import 'package:fitness/data/services/fitness/body_composition_service.dart';
import 'package:fitness/data/services/fitness/body_scan_storage.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/ui/features/fitness/views/body_composition_result_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final ScrollController _dateScrollCtrl = ScrollController();

  String? _selectedTone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FitnessViewModel>().loadFitnessPlans();
      _scrollToToday();
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
    _dateScrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!mounted) return;
    final idx   = _dayIndexFromToday(_selectedDate);
    final maxEx = _dateScrollCtrl.hasClients
        ? _dateScrollCtrl.position.maxScrollExtent
        : 0.0;
    if (_dateScrollCtrl.hasClients && idx >= 0) {
      const itemW = 80.0;
      final offset = idx * itemW - (MediaQuery.of(context).size.width / 2 - itemW / 2);
      _dateScrollCtrl.animateTo(
        offset.clamp(0.0, maxEx),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  int _dayIndexFromToday(DateTime date) {
    final t = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final d = DateTime(date.year, date.month, date.day);
    return d.difference(t).inDays;
  }

  String _shortName(String name, {int max = 15}) =>
      name.length <= max ? name : '${name.substring(0, max)}…';

  Future<void> _scanFoodItem() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null && mounted) {
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
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1280,
      );
      if (image == null || !mounted) return;
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StreakSheet(streak: streak),
    );
  }

  void _openTonePicker() {
    String? gender;
    try {
      gender = sl<SupabaseClient>().auth.currentUser?.userMetadata?['gender'] as String?;
    } catch (_) {}

    final userGender =
        (gender?.toLowerCase() == 'female' || gender?.toLowerCase() == 'f')
            ? 'female'
            : 'male';
    final toneList = List<String>.from(Constant.toneOptions.first[userGender] ?? []);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialog) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 4,
          child: SizedBox(
            width: 400,
            height: 500,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Pick your tone',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: toneList.isEmpty
                          ? const Center(
                              child: Text('No tone options available',
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: toneList.length,
                              itemBuilder: (_, i) {
                                final tone       = toneList[i];
                                final isSelected = _selectedTone == tone;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: GestureDetector(
                                    onTap: () => setDialog(
                                        () => setState(() => _selectedTone = tone)),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppPalete.borderColor.withValues(alpha: 0.3)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppPalete.borderColor
                                              : Colors.grey.withValues(alpha: 0.3),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              tone,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(Icons.check_circle,
                                                color: AppPalete.borderColor,
                                                size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: double.infinity,
                        child: AppWidgets.roundbtnText(
                          onPressed: _selectedTone != null
                              ? () {
                                  Navigator.of(dialogCtx).pop();
                                  Navigator.of(dialogCtx, rootNavigator: true).push(
                                    MaterialPageRoute(
                                      builder: (_) => MotivatePage(
                                        tone: _selectedTone!
                                            .toLowerCase()
                                            .replaceAll(' ', '-'),
                                      ),
                                    ),
                                  );
                                }
                              : () => ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a tone'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  ),
                          text: 'Motivate',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
              scrollController: _dateScrollCtrl,
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
                    _FoodScanCard(onTap: _scanFoodItem),

                    const SizedBox(height: 28),

                    // ── Body Composition Scan ────────────────────────────────
                    _SectionLabel(label: 'Body Composition'),
                    const SizedBox(height: 12),
                    _BodyScanCard(
                      imagePath: _bodyScanImagePath,
                      onCamera:  () => _pickBodyScanImage(ImageSource.camera),
                      onGallery: () => _pickBodyScanImage(ImageSource.gallery),
                      onClear:   () => setState(() => _bodyScanImagePath = null),
                    ),

                    const SizedBox(height: 28),

                    // ── Motivation ───────────────────────────────────────────
                    _SectionLabel(label: 'Your Motivation'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _openTonePicker,
                      child: _MotivationBanner(),
                    ),

                    const SizedBox(height: 28),

                    // ── Weekly Progress ──────────────────────────────────────
                    _SectionLabel(label: 'This Week'),
                    const SizedBox(height: 12),
                    _WeeklyProgressCard(
                      completedDates: fitnessVm.completedDates,
                      workoutMappings: fitnessVm.workoutMappings,
                    ),

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

// ── Weekly progress card ──────────────────────────────────────────────────────

class _WeeklyProgressCard extends StatelessWidget {
  final Set<DateTime> completedDates;
  final Map<DateTime, WorkoutDayMappingEntity> workoutMappings;
  const _WeeklyProgressCard({
    required this.completedDates,
    required this.workoutMappings,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Monday-anchored week
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) => DateTime(
          monday.year,
          monday.month,
          monday.day + i,
        ));

    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final done = days.where((d) => completedDates.contains(d)).length;
    final planned = days.where((d) => workoutMappings.containsKey(d)).length;
    final progress = planned == 0 ? 0.0 : (done / planned).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title + count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Workouts',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$done',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _kLime,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: ' / $planned',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kDimWhite,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // day dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day     = days[i];
              final isToday = day.year == today.year &&
                              day.month == today.month &&
                              day.day == today.day;
              final done    = completedDates.contains(day);
              final planned = workoutMappings.containsKey(day);
              final isPast  = day.isBefore(DateTime(today.year, today.month, today.day));

              Color dotColor;
              Color labelColor;
              if (done) {
                dotColor   = _kLime;
                labelColor = _kLime;
              } else if (isToday) {
                dotColor   = Colors.white.withValues(alpha: 0.5);
                labelColor = Colors.white;
              } else if (planned && isPast) {
                dotColor   = const Color(0xFFFF5B5B).withValues(alpha: 0.7);
                labelColor = _kDimWhite;
              } else if (planned) {
                dotColor   = Colors.white.withValues(alpha: 0.25);
                labelColor = _kDimWhite;
              } else {
                dotColor   = Colors.white.withValues(alpha: 0.08);
                labelColor = Colors.white.withValues(alpha: 0.3);
              }

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? _kLime.withValues(alpha: 0.15) : Colors.transparent,
                      border: Border.all(
                        color: dotColor,
                        width: isToday ? 2 : 1.5,
                      ),
                    ),
                    child: done
                        ? Icon(Icons.check_rounded, size: 16, color: _kLime)
                        : isToday
                            ? Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 16),

          // progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(_kLime),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            done == planned && planned > 0
                ? 'Full week complete! Outstanding work.'
                : done == 0
                    ? 'No workouts logged yet this week.'
                    : '$done of $planned planned workouts done.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: _kDimWhite,
              height: 1.4,
            ),
          ),
        ],
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

// ─── Collapsible date strip / full-month calendar ─────────────────────────────

class _CollapsibleDateStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ScrollController scrollController;
  final Map<DateTime, dynamic> workoutMappings;
  final Set<DateTime> completedDates;
  final void Function(DateTime) onDateSelected;
  final void Function(DateTime) onCompletedDateTapped;

  const _CollapsibleDateStrip({
    required this.selectedDate,
    required this.scrollController,
    required this.workoutMappings,
    required this.completedDates,
    required this.onDateSelected,
    required this.onCompletedDateTapped,
  });

  @override
  State<_CollapsibleDateStrip> createState() => _CollapsibleDateStripState();
}

class _CollapsibleDateStripState extends State<_CollapsibleDateStrip>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late DateTime _viewMonth;

  static const _kStripHeight    = 88.0;
  static const _kCalendarHeight = 360.0;
  static const _kWeekDays       = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _kMonthNames     = [
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

  Widget _buildStrip() {
    final today = DateTime.now();
    final dates = List.generate(7, (i) => today.add(Duration(days: i)));
    return SizedBox(
      height: _kStripHeight,
      child: ListView.builder(
        controller: widget.scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: dates.length,
        itemBuilder: (_, i) {
          final date        = dates[i];
          final norm        = DateTime(date.year, date.month, date.day);
          final isSelected  = _isSelected(date);
          final hasWorkout  = widget.workoutMappings.containsKey(norm);
          final isCompleted = widget.completedDates.contains(norm);
          return GestureDetector(
            onTap: () => _handleDateTap(date),
            child: _StripCell(
              date: date,
              isSelected: isSelected,
              hasWorkout: hasWorkout,
              isCompleted: isCompleted,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendar() {
    final days = _calendarDays();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Row(
            children: [
              _NavArrow(icon: Icons.chevron_left_rounded, onTap: _prevMonth),
              Expanded(
                child: Text(
                  '${_kMonthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              _NavArrow(icon: Icons.chevron_right_rounded, onTap: _nextMonth),
            ],
          ),
        ),
        Row(
          children: _kWeekDays.map((d) => Expanded(
            child: Center(
              child: Text(d,
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.35))),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: days.length,
          itemBuilder: (_, i) {
            final date = days[i];
            if (date == null) return const SizedBox.shrink();
            final norm        = DateTime(date.year, date.month, date.day);
            final isSelected  = _isSelected(date);
            final isToday     = _isToday(date);
            final hasWorkout  = widget.workoutMappings.containsKey(norm);
            final isCompleted = widget.completedDates.contains(norm);
            return GestureDetector(
              onTap: () => _handleDateTap(date),
              child: _CalendarCell(
                date: date,
                isSelected: isSelected,
                isToday: isToday,
                hasWorkout: hasWorkout,
                isCompleted: isCompleted,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: _kLime, label: 'Training'),
            const SizedBox(width: 20),
            _LegendDot(color: Colors.redAccent, label: 'Completed'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _toggleExpanded,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _expanded
                      ? _kLime.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _expanded
                        ? _kLime.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? 'Week' : 'Month',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: _expanded ? _kLime : Colors.white54),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 220),
                      turns: _expanded ? 0.5 : 0.0,
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: _expanded ? _kLime : Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          height: _expanded ? _kCalendarHeight : _kStripHeight,
          child: ClipRect(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 260),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _buildStrip(),
              secondChild: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _buildCalendar(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Strip cell ───────────────────────────────────────────────────────────────

class _StripCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected, hasWorkout, isCompleted;
  const _StripCell({
    required this.date,
    required this.isSelected,
    required this.hasWorkout,
    required this.isCompleted,
  });

  String get _dayLabel =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

  Color get _borderColor {
    if (isSelected)  return Colors.white.withValues(alpha: 0.4);
    if (isCompleted) return Colors.red.withValues(alpha: 0.8);
    if (hasWorkout)  return _kLime.withValues(alpha: 0.6);
    return Colors.white.withValues(alpha: 0.1);
  }

  double get _borderWidth =>
      (isSelected || isCompleted || hasWorkout) ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? _kLime.withValues(alpha: 0.15)
                  : Colors.transparent,
              border: Border.all(color: _borderColor, width: _borderWidth),
              boxShadow: isSelected
                  ? [BoxShadow(
                      color: _kLime.withValues(alpha: 0.12),
                      blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_dayLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: isSelected ? _kLime : Colors.white70)),
                const SizedBox(height: 2),
                Text('${date.day}',
                  style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: isSelected ? _kLime : Colors.white)),
              ],
            ),
          ),
          if ((hasWorkout || isCompleted) && !isSelected)
            Positioned(
              top: 4, right: 4,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.red : _kLime,
                ),
              ),
            ),
        ],
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? _kLime.withValues(alpha: 0.18)
            : isToday
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? _kLime.withValues(alpha: 0.7)
              : isToday
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.transparent,
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [BoxShadow(
                color: _kLime.withValues(alpha: 0.15),
                blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('${date.day}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
              color: isSelected
                  ? _kLime
                  : isToday
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.75))),
          if (hasWorkout || isCompleted)
            Positioned(
              bottom: 3,
              child: Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.redAccent : _kLime,
                  boxShadow: [
                    BoxShadow(
                      color: (isCompleted ? Colors.redAccent : _kLime)
                          .withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Icon(icon, color: Colors.white70, size: 20),
    ),
  );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 7, height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      const SizedBox(width: 5),
      Text(label,
        style: GoogleFonts.inter(
          fontSize: 11, color: Colors.white.withValues(alpha: 0.45))),
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
