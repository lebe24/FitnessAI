import 'package:fitness/ui/core/di.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/ui/features/home/view_models/upload_view_model.dart';
import 'package:fitness/ui/features/home/views/result_modal.dart';
import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ── BeFit AI Brand Palette ────────────────────────────────────────────────────
const _bgTop     = Color(0xFF060705);
const _bgBottom  = Color(0xFF0D0F14);
const _surface   = Color(0xFF1A2332);
const _surfaceEl = Color(0xFF121620);
const _border    = Color(0xFF2A2F3D);
const _borderCard= Color(0xFF2A3A4D);
const _lime      = Color(0xFFCCFF00);
const _textPri   = Colors.white;
const _textSub   = Color(0xFF9E9E9E);

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  late final UploadViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = sl<UploadViewModel>();
    _vm.addListener(_onError);
  }

  void _onError() {
    if (!mounted) return;
    if (_vm.error != null && !_vm.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.error!,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onError);
    _vm.dispose();
    super.dispose();
  }

  void _showSourcePicker(BuildContext ctx) {
    final vm = ctx.read<UploadViewModel>();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _SourcePickerSheet(
        onCamera: () { Navigator.pop(ctx); vm.pickFromCamera(); },
        onGallery: () { Navigator.pop(ctx); vm.pickFromGallery(); },
      ),
    );
  }

  void _openResultModal(BuildContext ctx, UploadViewModel vm) {
    final onboardingData =
        ctx.read<OnboardingViewModel>().data;
    showModalBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      context: ctx,
      builder: (modalCtx) => ChangeNotifierProvider.value(
        value: vm,
        child: ResultModalPage(
          userData: onboardingData,
          image: vm.image!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<UploadViewModel>(
        builder: (ctx, vm, _) => _PageContent(
          vm: vm,
          onPickImage: () => _showSourcePicker(ctx),
          onGenerate: () => _openResultModal(ctx, vm),
        ),
      ),
    );
  }
}

// ── Page content (stateless shell) ───────────────────────────────────────────
class _PageContent extends StatelessWidget {
  final UploadViewModel vm;
  final VoidCallback onPickImage;
  final VoidCallback onGenerate;

  const _PageContent({
    required this.vm,
    required this.onPickImage,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final user = sl<GetCurrentUser>()();
    final firstName = (user?.name ?? user?.email ?? 'Athlete').split(' ').first;

    return Scaffold(
      backgroundColor: _bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back button ──────────────────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Title ────────────────────────────────────────────────────
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _textPri,
                    ),
                    children: const [
                      TextSpan(text: 'Scan Your\n'),
                      TextSpan(
                        text: 'Physique',
                        style: TextStyle(
                            backgroundColor: _lime, color: Colors.black),
                      ),
                      TextSpan(text: ' 📸'),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 8),

                Text(
                  'Upload a clear full-body photo.\nOur AI will analyse your physique and build your plan.',
                  style: GoogleFonts.inter(
                      color: _textSub, fontSize: 13, height: 1.55),
                )
                    .animate(delay: 80.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // ── Upload zone ──────────────────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: (!vm.isLoading || vm.image != null)
                        ? onPickImage
                        : null,
                    child: _UploadZone(vm: vm),
                  )
                      .animate(delay: 120.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                ),

                const SizedBox(height: 20),

                // ── CTA area ─────────────────────────────────────────────────
                _CtaRow(vm: vm, onPickImage: onPickImage, onGenerate: onGenerate)
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 350.ms),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Upload zone ───────────────────────────────────────────────────────────────
class _UploadZone extends StatelessWidget {
  final UploadViewModel vm;
  const _UploadZone({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: vm.image != null
              ? _lime.withValues(alpha: 0.4)
              : _borderCard,
          width: vm.image != null ? 1.5 : 1.0,
        ),
        boxShadow: vm.image != null
            ? [
                BoxShadow(
                  color: _lime.withValues(alpha: 0.10),
                  blurRadius: 24,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _buildInner(),
      ),
    );
  }

  Widget _buildInner() {
    // Image loaded — show with gradient overlay
    if (vm.image != null && !vm.isLoading) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(vm.image!, fit: BoxFit.cover),
          // Gradient fade at bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
          // Swap photo hint
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz_rounded,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'Tap to change photo',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Loading while image selected
    if (vm.image != null && vm.isLoading) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(vm.image!, fit: BoxFit.cover),
          Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: const Center(
              child: CircularProgressIndicator(
                color: _lime,
                strokeWidth: 2.5,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
        ],
      );
    }

    // Empty state
    return _EmptyUploadState();
  }
}

class _EmptyUploadState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Glowing camera icon
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _lime.withValues(alpha: 0.18),
                    blurRadius: 36,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _lime.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _lime.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: _lime, size: 32),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Upload Your Photo',
          style: GoogleFonts.poppins(
            color: _textPri,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Camera or gallery — full body, good lighting',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: _textSub, fontSize: 12),
        ),
        const SizedBox(height: 24),
        // Dashed border hint pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HintPill(icon: Icons.camera_alt_rounded, label: 'Camera'),
            const SizedBox(width: 10),
            _HintPill(icon: Icons.photo_library_rounded, label: 'Gallery'),
          ],
        ),
      ],
    );
  }
}

class _HintPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HintPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceEl,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderCard),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _lime, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  color: _textPri,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── CTA row ───────────────────────────────────────────────────────────────────
class _CtaRow extends StatelessWidget {
  final UploadViewModel vm;
  final VoidCallback onPickImage;
  final VoidCallback onGenerate;
  const _CtaRow(
      {required this.vm, required this.onPickImage, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    if (vm.image == null) {
      // Primary upload CTA
      return GestureDetector(
        onTap: onPickImage,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _lime,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _lime.withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_photo_alternate_rounded,
                  color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text(
                'Select Photo',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // After image selected: two buttons
    return Row(
      children: [
        // Retake
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderCard),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: _textSub, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        // Generate
        Expanded(
          child: GestureDetector(
            onTap: vm.isLoading ? null : onGenerate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 54,
              decoration: BoxDecoration(
                color: vm.isLoading ? _surface : _lime,
                borderRadius: BorderRadius.circular(16),
                boxShadow: vm.isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: _lime.withValues(alpha: 0.30),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: vm.isLoading ? _textSub : Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    vm.isLoading ? 'Processing…' : 'Generate My Plan',
                    style: GoogleFonts.poppins(
                      color: vm.isLoading ? _textSub : Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Source picker bottom sheet ────────────────────────────────────────────────
class _SourcePickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _SourcePickerSheet(
      {required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0C12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2F3D),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Select Photo Source',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: onCamera,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: onGallery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderCard),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _lime.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _lime.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(icon, color: _lime, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

