import 'dart:math' as math;

import 'package:fitness/domain/energy/bot_settings.dart';
import 'package:fitness/ui/features/energy/view_models/energy_chat_controller.dart';
import 'package:flutter/material.dart';

const _kInk = Color(0xFF161B26);
const _kCheek = Color(0xFFFF9A5C);
const _kOrange = Color(0xFFFF6B3D);

/// The colours of one look.
class _Skin {
  final Color top;
  final Color bottom;

  /// Arms and feet.
  final Color shade;
  final Color belly;
  const _Skin(this.top, this.bottom, this.shade, this.belly);

  static _Skin of(BotMascot m) => switch (m) {
        BotMascot.flame =>
          const _Skin(Color(0xFFE9FF7A), Color(0xFFB4E000), Color(0xFF8AAE00), Color(0xFFF6FFC2)),
        BotMascot.robot =>
          const _Skin(Color(0xFFE3EAF7), Color(0xFF98A9CC), Color(0xFF6B7BA0), Color(0xFFF3F6FC)),
        BotMascot.droplet =>
          const _Skin(Color(0xFFB6EAFF), Color(0xFF45A8F2), Color(0xFF2E7FC4), Color(0xFFE2F6FF)),
        BotMascot.kettlebell =>
          const _Skin(Color(0xFFD9C4FF), Color(0xFF9468F0), Color(0xFF6E48C4), Color(0xFFEDE3FF)),
      };
}

/// The bot's mascot. Bobs, blinks and changes face with [mood]. Still when the
/// system asks for less motion.
class BotMascotView extends StatefulWidget {
  final BotMascot mascot;
  final double size;
  final BotMood mood;
  final String? semanticLabel;

  /// False draws it still, for small choices shown side by side.
  final bool animate;

  const BotMascotView({
    super.key,
    this.mascot = BotMascot.flame,
    this.size = 96,
    this.mood = BotMood.idle,
    this.semanticLabel,
    this.animate = true,
  });

  @override
  State<BotMascotView> createState() => _BotMascotViewState();
}

class _BotMascotViewState extends State<BotMascotView> with SingleTickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BotMascotView old) {
    super.didUpdateWidget(old);
    if (old.animate != widget.animate) _sync();
  }

  void _sync() {
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _loop.stop();
      _loop.value = 0;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.semanticLabel ?? '${widget.mascot.label} mascot',
        image: true,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _loop,
            builder: (_, __) => CustomPaint(
              size: Size.square(widget.size),
              painter: _MascotPainter(widget.mascot, _loop.value, widget.mood),
            ),
          ),
        ),
      );
}

class _MascotPainter extends CustomPainter {
  final BotMascot mascot;
  final double t;
  final BotMood mood;
  const _MascotPainter(this.mascot, this.t, this.mood);

  _Skin get _skin => _Skin.of(mascot);

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 100 × 100 board.
    canvas.scale(size.width / 100);
    final wave = math.sin(t * math.pi * 2);
    final bob = wave * (mood == BotMood.cheer ? 3.2 : 1.6);

    // Shadow stays on the floor while the body moves.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 95), width: 46 - bob * 2, height: 6),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.translate(0, bob);

    final feet = Paint()..color = _skin.shade;
    canvas.drawOval(Rect.fromCenter(center: const Offset(39, 90), width: 15, height: 9), feet);
    canvas.drawOval(Rect.fromCenter(center: const Offset(61, 90), width: 15, height: 9), feet);

    _arms(canvas);
    _behind(canvas);

    final body = _body();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skin.top, _skin.bottom],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 92)),
    );

    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 76), width: 40, height: 22),
        Paint()..color = _skin.belly.withValues(alpha: 0.7));

    _onTop(canvas, body);

    _face(canvas);
    if (mood == BotMood.cheer) _sparks(canvas);
  }

  Path _body() => switch (mascot) {
        BotMascot.flame => Path()
          ..moveTo(54, 4)
          ..cubicTo(58, 16, 70, 18, 77, 30)
          ..cubicTo(80, 27, 81, 24, 80, 20)
          ..cubicTo(90, 32, 87, 42, 84, 46)
          ..cubicTo(88, 76, 71, 90, 50, 90)
          ..cubicTo(29, 90, 13, 76, 16, 53)
          ..cubicTo(18, 34, 35, 28, 42, 18)
          ..cubicTo(46, 13, 52, 11, 54, 4)
          ..close(),
        BotMascot.robot => Path()
          ..addRRect(RRect.fromRectAndRadius(
              const Rect.fromLTRB(17, 28, 83, 90), const Radius.circular(22))),
        BotMascot.droplet => Path()
          ..moveTo(50, 5)
          ..cubicTo(60, 24, 85, 40, 85, 61)
          ..cubicTo(85, 80, 69, 90, 50, 90)
          ..cubicTo(31, 90, 15, 80, 15, 61)
          ..cubicTo(15, 40, 40, 24, 50, 5)
          ..close(),
        BotMascot.kettlebell => Path()
          ..moveTo(32, 33)
          ..cubicTo(40, 28, 60, 28, 68, 33)
          ..cubicTo(80, 40, 85, 52, 85, 63)
          ..cubicTo(85, 78, 76, 90, 66, 90)
          ..lineTo(34, 90)
          ..cubicTo(24, 90, 15, 78, 15, 63)
          ..cubicTo(15, 52, 20, 40, 32, 33)
          ..close(),
      };

  /// What sits behind the body: the kettlebell's handle, the robot's aerial and
  /// ear bolts.
  void _behind(Canvas canvas) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = _skin.shade;
    switch (mascot) {
      case BotMascot.kettlebell:
        canvas.drawPath(
          Path()
            ..moveTo(33, 38)
            ..cubicTo(24, 4, 76, 4, 67, 38),
          stroke..strokeWidth = 9,
        );
      case BotMascot.robot:
        canvas.drawLine(const Offset(50, 29), const Offset(50, 13), stroke..strokeWidth = 4);
        canvas.drawCircle(const Offset(50, 11), 6, Paint()..color = const Color(0xFFCCFF00));
        final bolt = Paint()..color = _skin.shade;
        for (final x in const [16.0, 84.0]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(center: Offset(x, 55), width: 8, height: 18), const Radius.circular(4)),
              bolt);
        }
      case BotMascot.flame || BotMascot.droplet:
        break;
    }
  }

  /// Details drawn over the body.
  void _onTop(Canvas canvas, Path body) {
    switch (mascot) {
      case BotMascot.flame:
        _sweatband(canvas, body, _kOrange);
      case BotMascot.droplet:
        canvas.drawOval(Rect.fromCenter(center: const Offset(40, 26), width: 8, height: 14),
            Paint()..color = Colors.white.withValues(alpha: 0.6));
        _sweatband(canvas, body, const Color(0xFF1E5AA8));
      case BotMascot.robot:
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTRB(24, 41, 76, 84), const Radius.circular(16)),
          Paint()..color = Colors.white.withValues(alpha: 0.35),
        );
      case BotMascot.kettlebell:
        canvas.drawOval(Rect.fromCenter(center: const Offset(31, 45), width: 12, height: 7),
            Paint()..color = Colors.white.withValues(alpha: 0.4));
    }
  }

  void _sweatband(Canvas canvas, Path body, Color color) {
    // Clipped to the head.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(
      Path()
        ..moveTo(10, 38)
        ..quadraticBezierTo(50, 28, 92, 38)
        ..lineTo(92, 47)
        ..quadraticBezierTo(50, 37, 10, 47)
        ..close(),
      Paint()..color = color,
    );
    canvas.drawPath(
      Path()
        ..moveTo(10, 42.5)
        ..quadraticBezierTo(50, 32.5, 92, 42.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white,
    );
    canvas.restore();
  }

  void _arms(Canvas canvas) {
    final arm = Paint()
      ..color = _skin.shade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round;
    final swing = math.sin(t * math.pi * 6) * 5;
    void draw(Offset from, Offset via, Offset to) => canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(via.dx, via.dy, to.dx, to.dy),
        arm);

    switch (mood) {
      case BotMood.cheer:
        draw(const Offset(22, 60), const Offset(5, 55), Offset(7, 37 + swing * 0.4));
        draw(const Offset(78, 60), const Offset(95, 55), Offset(93, 37 - swing * 0.4));
      case BotMood.greet:
        draw(const Offset(22, 62), const Offset(8, 68), const Offset(9, 77));
        draw(const Offset(78, 60), const Offset(94, 56), Offset(91 + swing, 40));
      case BotMood.thinking:
        draw(const Offset(22, 62), const Offset(8, 68), const Offset(9, 77));
        draw(const Offset(80, 66), const Offset(88, 78), const Offset(66, 73));
      case BotMood.idle:
        draw(const Offset(22, 62), const Offset(8, 68), const Offset(9, 77));
        draw(const Offset(78, 62), const Offset(92, 68), const Offset(91, 77));
    }
  }

  void _face(Canvas canvas) {
    final ink = Paint()..color = _kInk;
    final line = Paint()
      ..color = _kInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const left = Offset(38, 55), right = Offset(62, 55);
    final blink = t > 0.9 && t < 0.945;

    for (final c in const [left, right]) {
      if (mood == BotMood.cheer) {
        canvas.drawArc(Rect.fromCenter(center: c.translate(0, 2), width: 13, height: 11), math.pi, math.pi,
            false, line);
      } else if (blink) {
        canvas.drawLine(c.translate(-6, 0), c.translate(6, 0), line);
      } else {
        canvas.drawOval(Rect.fromCenter(center: c, width: 17, height: 19), Paint()..color = Colors.white);
        final look = mood == BotMood.thinking ? const Offset(2, -3.5) : const Offset(0, 1);
        canvas.drawCircle(c + look, 5.2, ink);
        canvas.drawCircle(c + look + const Offset(1.8, -2), 1.7, Paint()..color = Colors.white);
      }
    }

    final cheek = Paint()..color = _kCheek.withValues(alpha: 0.55);
    canvas.drawOval(Rect.fromCenter(center: const Offset(27, 66), width: 9, height: 6), cheek);
    canvas.drawOval(Rect.fromCenter(center: const Offset(73, 66), width: 9, height: 6), cheek);

    switch (mood) {
      case BotMood.cheer || BotMood.greet:
        final mouth = Path()
          ..moveTo(42, 67)
          ..quadraticBezierTo(50, 69, 58, 67)
          ..quadraticBezierTo(56, 79, 50, 79)
          ..quadraticBezierTo(44, 79, 42, 67)
          ..close();
        canvas.drawPath(mouth, ink);
        canvas.save();
        canvas.clipPath(mouth);
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 79), width: 11, height: 8),
            Paint()..color = _kOrange);
        canvas.restore();
      case BotMood.thinking:
        canvas.drawOval(Rect.fromCenter(center: const Offset(52, 70), width: 6, height: 5), ink);
      case BotMood.idle:
        canvas.drawArc(
            Rect.fromCenter(center: const Offset(50, 66), width: 15, height: 12), 0.3, math.pi - 0.6, false, line);
    }
  }

  void _sparks(Canvas canvas) {
    final p = Paint()..color = const Color(0xFFFFC93C);
    for (final (x, y, phase) in const [(14.0, 18.0, 0.0), (90.0, 12.0, 0.35), (6.0, 56.0, 0.65)]) {
      final r = 2 + 3 * (0.5 + 0.5 * math.sin((t + phase) * math.pi * 4));
      canvas.drawPath(
        Path()
          ..moveTo(x, y - r)
          ..quadraticBezierTo(x, y, x + r, y)
          ..quadraticBezierTo(x, y, x, y + r)
          ..quadraticBezierTo(x, y, x - r, y)
          ..quadraticBezierTo(x, y, x, y - r),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) => old.t != t || old.mood != mood || old.mascot != mascot;
}
