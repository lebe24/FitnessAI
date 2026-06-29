import 'dart:io';
import 'package:fitness/domain/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Chat palette ──────────────────────────────────────────────────────────────

class ChatPalette {
  final bool isDark;
  final Color bg;
  final Color surfaceEl;
  final Color surface;
  final Color surface2;
  final Color selectorBg;
  final Color border;
  final Color borderCard;
  final Color lime;
  final Color limeCode; // readable lime variant (bright in dark, dark-olive in light)
  final Color textPri;
  final Color textSub;
  final Color codeBg;
  final Color bgAi;
  final Color bgUser;

  const ChatPalette({
    required this.isDark,
    required this.bg,
    required this.surfaceEl,
    required this.surface,
    required this.surface2,
    required this.selectorBg,
    required this.border,
    required this.borderCard,
    required this.lime,
    required this.limeCode,
    required this.textPri,
    required this.textSub,
    required this.codeBg,
    required this.bgAi,
    required this.bgUser,
  });

  static const dark = ChatPalette(
    isDark: true,
    bg: Color(0xFF060705),
    surfaceEl: Color(0xFF121620),
    surface: Color(0xFF1A2332),
    surface2: Color(0xFF0A0C12),
    selectorBg: Color(0xFF0D1018),
    border: Color(0xFF2A2F3D),
    borderCard: Color(0xFF2A3A4D),
    lime: Color(0xFFCCFF00),
    limeCode: Color(0xFFCCFF00),
    textPri: Colors.white,
    textSub: Color(0xFF9E9E9E),
    codeBg: Color(0xFF0A0C12),
    bgAi: Color(0xFF121620),
    bgUser: Color(0xFF1A2332),
  );

  static const light = ChatPalette(
    isDark: false,
    bg: Color(0xFFF3F5F0),
    surfaceEl: Color(0xFFFFFFFF),
    surface: Color(0xFFEBEEE8),
    surface2: Color(0xFFE2E6DD),
    selectorBg: Color(0xFFEDF0EC),
    border: Color(0xFFCDD2C8),
    borderCard: Color(0xFFC0C6BA),
    lime: Color(0xFFCCFF00),
    limeCode: Color(0xFF4D7A00),
    textPri: Color(0xFF0D0F14),
    textSub: Color(0xFF6B7280),
    codeBg: Color(0xFFE8EBE4),
    bgAi: Color(0xFFFFFFFF),
    bgUser: Color(0xFFDDE8F8),
  );

  /// Lime that stays readable on any background — bright in dark, dark-olive in light.
  Color get limeText => isDark ? lime : limeCode;

  /// Linearly interpolate between two palettes (used for animated transitions).
  static ChatPalette lerp(ChatPalette a, ChatPalette b, double t) {
    return ChatPalette(
      isDark: t < 0.5,
      bg:         Color.lerp(a.bg,         b.bg,         t)!,
      surfaceEl:  Color.lerp(a.surfaceEl,  b.surfaceEl,  t)!,
      surface:    Color.lerp(a.surface,    b.surface,    t)!,
      surface2:   Color.lerp(a.surface2,   b.surface2,   t)!,
      selectorBg: Color.lerp(a.selectorBg, b.selectorBg, t)!,
      border:     Color.lerp(a.border,     b.border,     t)!,
      borderCard: Color.lerp(a.borderCard, b.borderCard, t)!,
      lime:       Color.lerp(a.lime,       b.lime,       t)!,
      limeCode:   Color.lerp(a.limeCode,   b.limeCode,   t)!,
      textPri:    Color.lerp(a.textPri,    b.textPri,    t)!,
      textSub:    Color.lerp(a.textSub,    b.textSub,    t)!,
      codeBg:     Color.lerp(a.codeBg,     b.codeBg,     t)!,
      bgAi:       Color.lerp(a.bgAi,       b.bgAi,       t)!,
      bgUser:     Color.lerp(a.bgUser,     b.bgUser,     t)!,
    );
  }
}

// ── Theme scope (InheritedWidget) ─────────────────────────────────────────────

class ChatThemeScope extends InheritedWidget {
  final ChatPalette palette;

  const ChatThemeScope({
    super.key,
    required this.palette,
    required super.child,
  });

  static ChatPalette of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<ChatThemeScope>()
            ?.palette ??
        ChatPalette.dark;
  }

  @override
  bool updateShouldNotify(ChatThemeScope old) => old.palette != palette;
}

// ── Chat message bubble ───────────────────────────────────────────────────────

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;

  /// Called when the user confirms an interactive selection.
  final void Function(String)? onInteraction;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return message.isFromUser
        ? _UserBubble(message: message)
        : _AiBubble(message: message, onInteraction: onInteraction);
  }
}

// ── User bubble ───────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final ChatMessageEntity message;
  const _UserBubble({required this.message});

  String? get _caption {
    final t = message.message;
    if (t == '📷 [image attached]') return null;
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    final maxW = MediaQuery.of(context).size.width * 0.72;
    final hasImage = message.imagePath != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ── Image attachment ─────────────────────────────────────
                  if (hasImage)
                    GestureDetector(
                      onTap: () =>
                          _openImageViewer(context, message.imagePath!),
                      child: Hero(
                        tag: 'chat_img_${message.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft:
                                Radius.circular(_caption != null ? 4 : 18),
                            bottomRight:
                                Radius.circular(_caption != null ? 4 : 4),
                          ),
                          child: Image.file(
                            File(message.imagePath!),
                            width: maxW,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  // ── Caption / text ───────────────────────────────────────
                  if (_caption != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: p.bgUser,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(hasImage ? 4 : 18),
                          topRight: Radius.circular(hasImage ? 4 : 18),
                          bottomLeft: const Radius.circular(18),
                          bottomRight: const Radius.circular(4),
                        ),
                        border: Border.all(
                            color: p.borderCard.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        _caption!,
                        style: GoogleFonts.inter(
                          color: p.textPri,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: p.lime.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: p.lime.withValues(alpha: 0.30), width: 1.5),
            ),
            child: Icon(Icons.person_rounded, size: 15, color: p.lime),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 250.ms, curve: Curves.easeOut)
          .slideY(
              begin: 0.08, end: 0, duration: 250.ms, curve: Curves.easeOut),
    );
  }

  void _openImageViewer(BuildContext context, String path) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _ImageViewerPage(
          path: path,
          heroTag: 'chat_img_${message.id}',
        ),
      ),
    );
  }
}

// ── Full-screen image viewer ──────────────────────────────────────────────────

class _ImageViewerPage extends StatelessWidget {
  final String path;
  final String heroTag;
  const _ImageViewerPage({required this.path, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Hero(
            tag: heroTag,
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(path)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── AI bubble ─────────────────────────────────────────────────────────────────

class _AiBubble extends StatefulWidget {
  final ChatMessageEntity message;
  final void Function(String)? onInteraction;
  const _AiBubble({required this.message, this.onInteraction});

  @override
  State<_AiBubble> createState() => _AiBubbleState();
}

class _AiBubbleState extends State<_AiBubble>
    with SingleTickerProviderStateMixin {
  static final Set<String> _done = {};

  late final AnimationController _ctrl;
  late final bool _shouldAnimate;

  bool get _isNew =>
      DateTime.now().difference(widget.message.timestamp).inSeconds < 15;

  @override
  void initState() {
    super.initState();
    _shouldAnimate = _isNew && !_done.contains(widget.message.id);

    final len = widget.message.message.length;
    final ms = (_shouldAnimate ? (len * 33).clamp(400, 2800) : 0).toInt();

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );

    if (_shouldAnimate) {
      _ctrl.forward().then((_) {
        _done.add(widget.message.id);
        if (mounted) setState(() {});
      });
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    final isTyping = _shouldAnimate && !_done.contains(widget.message.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              color: p.lime.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: p.lime.withValues(alpha: 0.30), width: 1.5),
            ),
            child: Icon(Icons.smart_toy_rounded, size: 16, color: p.lime),
          ),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender label
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    'BeFit Coach',
                    style: GoogleFonts.poppins(
                      color: p.limeText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: p.bgAi,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: p.border),
                    boxShadow: p.isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                  ),
                  child: isTyping
                      ? _TypewriterBody(
                          fullText: widget.message.message,
                          controller: _ctrl,
                        )
                      : _MarkdownBody(text: widget.message.message),
                ),

                // Interactive widget (chip selector etc.)
                if (!isTyping && widget.message.uiComponent != null)
                  _InteractiveWidget(
                    component: widget.message.uiComponent!,
                    messageId: widget.message.id,
                    onConfirm: widget.onInteraction,
                  ),

                // Timestamp + copy
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      Text(
                        _formatTime(widget.message.timestamp),
                        style: GoogleFonts.inter(
                            color: p.textSub, fontSize: 10),
                      ),
                      const SizedBox(width: 12),
                      _ActionBtn(
                        icon: Icons.copy_rounded,
                        size: 13,
                        onTap: () => Clipboard.setData(
                            ClipboardData(text: widget.message.message)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
          .slideY(
              begin: 0.10, end: 0, duration: 300.ms, curve: Curves.easeOut),
    );
  }

  String _formatTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${ts.hour.toString().padLeft(2, '0')}:'
        '${ts.minute.toString().padLeft(2, '0')}';
  }
}

// ── Interactive widget ────────────────────────────────────────────────────────

final _confirmedInteractions = <String>{};

class _InteractiveWidget extends StatefulWidget {
  final Map<String, dynamic> component;
  final String messageId;
  final void Function(String)? onConfirm;

  const _InteractiveWidget({
    required this.component,
    required this.messageId,
    this.onConfirm,
  });

  @override
  State<_InteractiveWidget> createState() => _InteractiveWidgetState();
}

class _InteractiveWidgetState extends State<_InteractiveWidget> {
  final Set<String> _selected = {};
  bool _confirmed = false;

  bool get _multi => widget.component['multi'] as bool? ?? false;
  String get _title => widget.component['title'] as String? ?? '';
  String get _id => widget.component['id'] as String? ?? '';

  List<Map<String, dynamic>> get _options {
    final raw = widget.component['options'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  @override
  void initState() {
    super.initState();
    _confirmed = _confirmedInteractions.contains(widget.messageId);
  }

  void _toggle(String id) {
    setState(() {
      if (_multi) {
        if (_selected.contains(id)) {
          _selected.remove(id);
        } else {
          _selected.add(id);
        }
      } else {
        _selected
          ..clear()
          ..add(id);
        _confirm();
      }
    });
  }

  void _confirm() {
    if (_selected.isEmpty) return;
    _confirmedInteractions.add(widget.messageId);
    setState(() => _confirmed = true);

    final labels = _options
        .where((o) => _selected.contains(o['id'] as String? ?? ''))
        .map((o) => o['label'] as String? ?? '')
        .join(', ');

    widget.onConfirm?.call(_buildSummary(labels));
  }

  String _buildSummary(String labels) {
    switch (_id) {
      case 'muscle_groups':
        return 'Muscle groups I want to target: $labels';
      case 'training_days':
        return 'I want to train $labels';
      case 'goal':
        return 'My primary goal is: $labels';
      case 'experience':
        return 'My experience level is: $labels';
      case 'equipment':
        return 'Available equipment: $labels';
      case 'session_duration':
        return 'My session duration: $labels';
      default:
        return '$_title $labels';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _confirmed
          ? _ConfirmedView(options: _options, selected: _selected)
          : _SelectorView(
              title: _title,
              options: _options,
              selected: _selected,
              multi: _multi,
              onToggle: _toggle,
              onConfirm: _multi ? _confirm : null,
            ),
    )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: 0.06, end: 0, duration: 300.ms);
  }
}

// ── Confirmed (locked) view ───────────────────────────────────────────────────

class _ConfirmedView extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final Set<String> selected;
  const _ConfirmedView({required this.options, required this.selected});

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    final labels = options
        .where((o) => selected.contains(o['id'] as String? ?? ''))
        .map((o) {
          final emoji = o['emoji'] as String? ?? '';
          final label = o['label'] as String? ?? '';
          return emoji.isNotEmpty ? '$emoji $label' : label;
        })
        .toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: labels
          .map(
            (l) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.lime.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.lime.withValues(alpha: 0.4)),
              ),
              child: Text(
                l,
                style: GoogleFonts.poppins(
                  color: p.limeText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Active selector view ──────────────────────────────────────────────────────

class _SelectorView extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final Set<String> selected;
  final bool multi;
  final void Function(String) onToggle;
  final VoidCallback? onConfirm;

  const _SelectorView({
    required this.title,
    required this.options,
    required this.selected,
    required this.multi,
    required this.onToggle,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: p.selectorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: p.lime,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: p.textPri,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (multi)
                Text(
                  'Pick all that apply',
                  style: GoogleFonts.inter(color: p.textSub, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final id = opt['id'] as String? ?? '';
              final label = opt['label'] as String? ?? '';
              final emoji = opt['emoji'] as String? ?? '';
              return _Chip(
                label: label,
                emoji: emoji,
                selected: selected.contains(id),
                onTap: () => onToggle(id),
              );
            }).toList(),
          ),

          if (multi && onConfirm != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: selected.isNotEmpty ? onConfirm : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected.isNotEmpty ? p.lime : p.border,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected.isNotEmpty
                        ? [
                            BoxShadow(
                              color: p.lime.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: GoogleFonts.poppins(
                          color: selected.isNotEmpty
                              ? Colors.black
                              : p.textSub,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color:
                            selected.isNotEmpty ? Colors.black : p.textSub,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Individual chip ───────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : p.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? p.lime : p.borderCard,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: p.lime.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji.isNotEmpty) ...[
              Text(
                emoji,
                style: const TextStyle(
                  fontSize: 14,
                  inherit: false,
                  fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji'],
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                color: selected ? p.lime : p.textPri,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 5),
              Icon(Icons.check_rounded, color: p.lime, size: 13),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Typewriter body ───────────────────────────────────────────────────────────

class _TypewriterBody extends AnimatedWidget {
  final String fullText;
  const _TypewriterBody({
    required this.fullText,
    required AnimationController controller,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    final ctrl = listenable as AnimationController;
    final visible =
        (ctrl.value * fullText.length).round().clamp(0, fullText.length);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            fullText.substring(0, visible),
            style:
                GoogleFonts.inter(color: p.textPri, fontSize: 15, height: 1.5),
          ),
        ),
        _BlinkingCursor(),
      ],
    );
  }
}

class _BlinkingCursor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    return Container(
      width: 2,
      height: 16,
      margin: const EdgeInsets.only(left: 2, bottom: 1),
      decoration: BoxDecoration(
        color: p.lime,
        borderRadius: BorderRadius.circular(1),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 500.ms)
        .then()
        .fadeOut(duration: 500.ms);
  }
}

// ── Full markdown body ────────────────────────────────────────────────────────

class _MarkdownBody extends StatelessWidget {
  final String text;
  const _MarkdownBody({required this.text});

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.inter(color: p.textPri, fontSize: 15, height: 1.5),
        h1: GoogleFonts.poppins(
            color: p.textPri, fontSize: 20, fontWeight: FontWeight.bold),
        h2: GoogleFonts.poppins(
            color: p.textPri, fontSize: 18, fontWeight: FontWeight.bold),
        h3: GoogleFonts.poppins(
            color: p.textPri, fontSize: 16, fontWeight: FontWeight.w600),
        strong: GoogleFonts.inter(
            color: p.textPri, fontSize: 15, fontWeight: FontWeight.w700),
        em: GoogleFonts.inter(
            color: p.textPri, fontSize: 15, fontStyle: FontStyle.italic),
        code: GoogleFonts.jetBrainsMono(
            color: p.limeCode, fontSize: 13, backgroundColor: p.codeBg),
        codeblockDecoration: BoxDecoration(
          color: p.codeBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: p.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
        codeblockPadding: const EdgeInsets.all(14),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: p.lime, width: 3)),
          color: p.lime.withValues(alpha: 0.05),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        listBullet: GoogleFonts.inter(color: p.lime, fontSize: 15),
        tableHead: GoogleFonts.poppins(
            color: p.textPri, fontWeight: FontWeight.w700),
        tableBody: GoogleFonts.inter(color: p.textPri),
        tableBorder: TableBorder.all(color: p.border),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.border)),
        ),
      ),
      builders: {'code': _CodeBlockBuilder(p: p)},
    );
  }
}

// ── Code block builder ────────────────────────────────────────────────────────

class _CodeBlockBuilder extends MarkdownElementBuilder {
  final ChatPalette p;
  _CodeBlockBuilder({required this.p});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    dynamic element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent as String;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: p.codeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: p.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: p.isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('code',
                    style:
                        GoogleFonts.inter(color: p.textSub, fontSize: 11)),
                _ActionBtn(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  size: 12,
                  onTap: () =>
                      Clipboard.setData(ClipboardData(text: code)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              code,
              style: GoogleFonts.jetBrainsMono(
                color: p.isDark
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFF1A1A2E),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String? label;
  final double size;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.size,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: p.textSub),
          if (label != null) ...[
            const SizedBox(width: 3),
            Text(label!,
                style: GoogleFonts.inter(color: p.textSub, fontSize: size)),
          ],
        ],
      ),
    );
  }
}
