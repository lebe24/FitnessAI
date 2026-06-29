import 'package:fitness/ui/core/constants/assets.dart';
import 'package:fitness/ui/core/di.dart' as di;
import 'package:fitness/ui/features/auth/view_models/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _lime = Color(0xFFCCFF00);

class AuthLoginPage extends StatelessWidget {
  const AuthLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => di.sl<AuthViewModel>(),
      child: const _AuthLoginBody(),
    );
  }
}

class _AuthLoginBody extends StatefulWidget {
  const _AuthLoginBody();

  @override
  State<_AuthLoginBody> createState() => _AuthLoginBodyState();
}

class _AuthLoginBodyState extends State<_AuthLoginBody> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showEmailField = false;
  late final AuthViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<AuthViewModel>();
    _vm.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = _vm;
      if (vm.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1A1A2E),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vm.error!,
                    style:
                        GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
        vm.clearError();
      }
      if (vm.isAuthenticated) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _vm.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // ── Split dark background ─────────────────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF060705), Color(0xFF0D0F14)],
                      stops: [0.5, 0.5],
                    ),
                  ),
                ),
              ),

              // ── Hero image fading out toward bottom ───────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 285,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.transparent],
                      stops: [0.55, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    ImagePath.loginCover,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),

              // ── Top bar: back button left, logo centred ───────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go('/welcome'),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white24, width: 1),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ).animate().fadeIn(duration: 600.ms),

                        // Centred logo
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              ImagePath.appLogo,
                              height: 36,
                              fit: BoxFit.contain,
                            ).animate().fadeIn(duration: 600.ms),
                          ),
                        ),

                        // Balancing spacer keeps logo visually centred
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom content ────────────────────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                bottom: bottomInset > 0
                    ? bottomInset + 16
                    : size.height * 0.045,
                left: 24,
                right: 24,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Headline
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.15,
                          ),
                          children: const [
                            TextSpan(text: 'Welcome '),
                            TextSpan(
                              text: 'Back',
                              style: TextStyle(
                                color: Colors.black,
                                backgroundColor: _lime,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 700.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 6),

                      Text(
                        'Sign in to continue your fitness journey.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white38,
                          height: 1.4,
                        ),
                      ).animate(delay: 350.ms).fadeIn(duration: 600.ms),

                      const SizedBox(height: 28),

                      // Google sign-in
                      _GoogleButton(onPressed: () => vm.signInWithGoogle())
                          .animate(delay: 450.ms)
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 14),

                      // "or" divider
                      Row(
                        children: [
                          const Expanded(
                              child:
                                  Divider(color: Colors.white10, thickness: 1)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'or',
                              style: GoogleFonts.inter(
                                  color: Colors.white24, fontSize: 13),
                            ),
                          ),
                          const Expanded(
                              child:
                                  Divider(color: Colors.white10, thickness: 1)),
                        ],
                      ).animate(delay: 500.ms).fadeIn(duration: 500.ms),

                      const SizedBox(height: 14),

                      // Gmail / email option
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 280),
                        crossFadeState: _showEmailField
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: _GmailOutlinedButton(
                          onTap: () => setState(
                              () => _showEmailField = !_showEmailField),
                        )
                            .animate(delay: 550.ms)
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.1, end: 0),
                        secondChild: _GmailForm(
                          controller: _emailController,
                          formKey: _formKey,
                          vm: vm,
                          onCancel: () =>
                              setState(() => _showEmailField = false),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white24,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Loading overlay ──────────────────────────────────────────
              if (vm.isLoading) const _LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google Sign-In Button
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.10),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleLogo(),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        size: const Size(22, 22),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;

    void drawArc(Color color, double startAngle, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.17
          ..strokeCap = StrokeCap.butt,
      );
    }

    const pi = 3.14159265;
    drawArc(const Color(0xFF4285F4), -pi / 2, pi / 2);
    drawArc(const Color(0xFF34A853), 0, pi / 2);
    drawArc(const Color(0xFFFBBC05), pi / 2, pi / 2);
    drawArc(const Color(0xFFEA4335), pi, pi / 2);

    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r, c.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = size.height * 0.17
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Gmail outlined button
// ─────────────────────────────────────────────────────────────────────────────

class _GmailOutlinedButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GmailOutlinedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, color: Colors.white54, size: 19),
            const SizedBox(width: 10),
            Text(
              'Continue with Gmail',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gmail email form
// ─────────────────────────────────────────────────────────────────────────────

class _GmailForm extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final AuthViewModel vm;
  final VoidCallback onCancel;

  const _GmailForm({
    required this.controller,
    required this.formKey,
    required this.vm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          cursorColor: _lime,
          decoration: InputDecoration(
            hintText: 'example@gmail.com',
            hintStyle:
                GoogleFonts.poppins(color: Colors.white30, fontSize: 14),
            prefixIcon: const Icon(Icons.alternate_email_rounded,
                color: Colors.white30, size: 19),
            filled: true,
            fillColor: const Color(0xFF141720),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFF252A38), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _lime, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle:
                GoogleFonts.inter(fontSize: 11, color: Colors.redAccent),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your Gmail address';
            if (!v.toLowerCase().trim().endsWith('@gmail.com')) {
              return 'Please enter a valid Gmail address';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onCancel,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  if (formKey.currentState!.validate()) {
                    vm.signInWithGmail(controller.text.trim());
                  }
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: _lime,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _lime.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading overlay
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1117),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  color: _lime,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Signing you in...',
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
