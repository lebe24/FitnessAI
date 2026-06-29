import 'dart:async';
import 'dart:io';
import 'package:fitness/data/models/home/workout_plan_model.dart';
import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/data/services/chat/chat_plan_service.dart';
import 'package:fitness/domain/use_cases/storage/save_fitness_plan_usecase.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/chat/view_models/chat_view_model.dart';
import 'package:fitness/ui/features/chat/views/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// ── Suggestion prompts ────────────────────────────────────────────────────────
const _suggestions = [
  ("💪", "Can you help me with my existing workout plan?"),
  ("🥗", "What should I eat today?"),
  ("🔥", "How do I build muscle faster?"),
  ("📈", "Track my progress"),
];

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final dynamic workoutPlan;
  final OnboardingData? onboardingData;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.workoutPlan,
    this.onboardingData,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController  = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode       = FocusNode();
  final _picker          = ImagePicker();
  bool    _hasText          = false;
  String? _pendingImagePath;
  bool    _isDark           = true;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatViewModel>().connect(
            widget.userId,
            widget.userName,
            workoutPlan: widget.workoutPlan,
          );
    });
  }

  void _onTextChanged() {
    final has = _textController.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleTheme() => setState(() => _isDark = !_isDark);

  void _send([String? preset]) {
    final text  = preset ?? _textController.text.trim();
    final image = _pendingImagePath;
    if (text.isEmpty && image == null) return;
    if (preset == null) _textController.clear();
    setState(() => _pendingImagePath = null);
    context.read<ChatViewModel>().sendMessage(
          text.isEmpty ? '📷 [image attached]' : text,
          widget.userId,
          imagePath: image,
        );
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1200);
      if (picked != null && mounted) {
        setState(() => _pendingImagePath = picked.path);
        _focusNode.requestFocus();
      }
    } catch (_) {}
  }

  void _showImageSourceSheet() {
    final p = _isDark ? ChatPalette.dark : ChatPalette.light;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChatThemeScope(
        palette: p,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: p.border, borderRadius: BorderRadius.circular(2)),
                ),
                Text('Attach an Image',
                  style: GoogleFonts.poppins(
                    color: p.textPri, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _SourceTile(
                      icon: Icons.camera_alt_rounded, label: 'Camera',
                      onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _SourceTile(
                      icon: Icons.photo_library_rounded, label: 'Gallery',
                      onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showGeneratePlanSheet(
    BuildContext context,
    ChatViewModel vm,
    ChatPalette p,
  ) {
    final conversation = vm.messages
        .map((m) => '${m.isFromUser ? "User" : "Coach"}: ${m.message}')
        .join('\n');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanGenerationSheet(
        conversation: conversation,
        onboardingData: widget.onboardingData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, vm, _) {
        if (vm.messages.isNotEmpty) _scrollToBottom();

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: _isDark ? 0.0 : 1.0),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
          builder: (context, t, _) {
            final p = ChatPalette.lerp(ChatPalette.dark, ChatPalette.light, t);

            return ChatThemeScope(
              palette: p,
              child: Scaffold(
                backgroundColor: p.bg,
                appBar: _AppBar(
                  vm: vm,
                  isDark: _isDark,
                  onClear: vm.clearMessages,
                  onToggleTheme: _toggleTheme,
                ),
                floatingActionButton: vm.messages.isNotEmpty
                    ? _GeneratePlanFab(onTap: () => _showGeneratePlanSheet(context, vm, p))
                    : null,
                body: Column(
                  children: [
                    if (!vm.isConnected && !vm.isConnecting)
                      _ReconnectBanner(
                        error: vm.error,
                        onRetry: () => vm.connect(
                          widget.userId,
                          widget.userName,
                          workoutPlan: widget.workoutPlan,
                        ),
                      ),

                    Expanded(
                      child: vm.isConnecting
                          ? _ConnectingView()
                          : vm.messages.isEmpty
                              ? _EmptyView(
                                  userName: widget.userName,
                                  onSuggestion: _send,
                                )
                              : GestureDetector(
                                  onTap: _focusNode.unfocus,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                                    itemCount: vm.messages.length,
                                    itemBuilder: (_, i) => ChatMessageBubble(
                                      message: vm.messages[i],
                                      onInteraction: _send,
                                    ),
                                  ),
                                ),
                    ),

                    if (vm.isSending) const _TypingIndicator(),

                    _InputBar(
                      controller: _textController,
                      focusNode: _focusNode,
                      hasText: _hasText,
                      canSend: vm.isConnected && !vm.isSending,
                      isConnected: vm.isConnected,
                      onSend: _send,
                      pendingImage: _pendingImagePath,
                      onAttach: _showImageSourceSheet,
                      onClearImage: () => setState(() => _pendingImagePath = null),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatViewModel vm;
  final VoidCallback onClear;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const _AppBar({
    required this.vm,
    required this.isDark,
    required this.onClear,
    required this.onToggleTheme,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);

    return AppBar(
      backgroundColor: p.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: p.textPri.withValues(alpha: 0.7),
            size: 18,
          ),
        ),
      ),
      title: Row(
        children: [
          // Status dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 8, height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: vm.isConnected
                  ? const Color(0xFF4CAF50)
                  : vm.isConnecting
                      ? Colors.amber
                      : p.border,
              boxShadow: vm.isConnected
                  ? [BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                      blurRadius: 6,
                    )]
                  : null,
            ),
          ),
          Text(
            'BeFit Coach',
            style: GoogleFonts.poppins(
              color: p.textPri,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.lime.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.lime.withValues(alpha: 0.2)),
            ),
            child: Text(
              'AI',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: p.limeText,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: p.textSub, size: 20),
          color: p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: p.borderCard),
          ),
          onSelected: (v) {
            if (v == 'clear') onClear();
            if (v == 'toggle') onToggleTheme();
          },
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              value: 'toggle',
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                      child: child,
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      key: ValueKey(isDark),
                      size: 16,
                      color: isDark
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFF5A6A8A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(isDark ? 'Light mode' : 'Dark mode',
                    style: GoogleFonts.inter(color: p.textPri, fontSize: 13)),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 34, height: 18,
                    decoration: BoxDecoration(
                      color: isDark ? p.borderCard : p.lime,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut,
                      alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        width: 14, height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isDark ? p.textSub : Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'clear',
              child: Row(
                children: [
                  const Icon(Icons.delete_sweep_rounded,
                      color: Colors.redAccent, size: 16),
                  const SizedBox(width: 10),
                  Text('Clear chat',
                      style: GoogleFonts.inter(color: p.textPri, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Connecting view ───────────────────────────────────────────────────────────

class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(
              color: p.lime, strokeWidth: 2, strokeCap: StrokeCap.round),
          ),
          const SizedBox(height: 16),
          Text('Connecting to your coach…',
            style: GoogleFonts.inter(color: p.textSub, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Empty / welcome view ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String userName;
  final void Function(String) onSuggestion;
  const _EmptyView({required this.userName, required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    final p    = ChatThemeScope.of(context);
    final first = userName.split(' ').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
      child: Column(
        children: [
          // ── Large watermark wordmark ──
          Text(
            'BeFit\nCoach',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 80,
              fontWeight: FontWeight.w800,
              color: p.textPri.withValues(alpha: p.isDark ? 0.04 : 0.05),
              height: 0.88,
              letterSpacing: -3,
            ),
          ),

          const SizedBox(height: 28),

          // ── Greeting ──
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Hey $first ',
                  style: GoogleFonts.poppins(
                    color: p.textPri,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const TextSpan(
                  text: '👋',
                  style: TextStyle(
                    fontSize: 22,
                    inherit: false,
                    fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji'],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Your personal AI fitness coach.\nAsk me to generate a training plan, check your diet,\nor track your progress.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: p.textSub.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.65,
            ),
          ),

          const SizedBox(height: 36),

          // ── Divider label ──
          Row(
            children: [
              Expanded(child: Divider(color: p.border.withValues(alpha: 0.5), height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Try asking',
                  style: GoogleFonts.inter(
                    color: p.textSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Expanded(child: Divider(color: p.border.withValues(alpha: 0.5), height: 1)),
            ],
          ),

          const SizedBox(height: 16),

          // ── Suggestion chips ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _suggestions
                .map((s) => _SuggestionChip(
                      emoji: s.$1,
                      label: s.$2,
                      onTap: () => onSuggestion(s.$2),
                    ))
                .toList(),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.04, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _SuggestionChip extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _SuggestionChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji,
              style: const TextStyle(
                fontSize: 14, inherit: false,
                fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji'],
              ),
            ),
            const SizedBox(width: 6),
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: p.textPri.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: p.lime, shape: BoxShape.circle),
          ),
          Text(
            'Coach is thinking…',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: p.textSub,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 600.ms)
        .then()
        .fadeOut(duration: 600.ms);
  }
}

// ── Input bar (Perplexity-style card) ─────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText, canSend, isConnected;
  final VoidCallback onSend;
  final String? pendingImage;
  final VoidCallback onAttach;
  final VoidCallback onClearImage;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.canSend,
    required this.isConnected,
    required this.onSend,
    required this.onAttach,
    required this.onClearImage,
    this.pendingImage,
  });

  bool get _canSendNow => canSend && (hasText || pendingImage != null);

  @override
  Widget build(BuildContext context) {
    final p         = ChatThemeScope.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 16),
      child: Container(
        decoration: BoxDecoration(
          color: p.surfaceEl,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.border, width: 1),
          boxShadow: p.isDark
              ? null
              : [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12, offset: const Offset(0, 4),
                )],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Pending image preview ──
            if (pendingImage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: _ImagePreview(path: pendingImage!, onRemove: onClearImage),
              ),

            // ── Text input ──
            Theme(
              data: p.isDark ? ThemeData.dark() : ThemeData.light(),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: canSend,
                maxLines: null,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                cursorColor: p.lime,
                style: GoogleFonts.inter(
                  color: p.textPri, fontSize: 15, height: 1.4),
                decoration: InputDecoration(
                  hintText: isConnected
                      ? pendingImage != null ? 'Add a caption…' : 'Ask anything…'
                      : 'Not connected',
                  hintStyle: GoogleFonts.inter(
                    color: p.textSub.withValues(alpha: 0.5),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                ),
              ),
            ),

            // ── Bottom action row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  // + / attach
                  _IconBtn(
                    onTap: canSend ? onAttach : null,
                    child: Icon(
                      pendingImage != null
                          ? Icons.image_rounded
                          : Icons.add_rounded,
                      size: 20,
                      color: pendingImage != null
                          ? p.lime
                          : p.textSub.withValues(alpha: 0.7),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // "Coach" model pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.lime.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.lime.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                          size: 11, color: p.limeText.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text('Coach',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: p.limeText.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Camera
                  _IconBtn(
                    onTap: canSend ? onAttach : null,
                    child: Icon(Icons.camera_alt_rounded,
                      size: 18, color: p.textSub.withValues(alpha: 0.5)),
                  ),

                  const SizedBox(width: 6),

                  // Send button
                  GestureDetector(
                    onTap: _canSendNow ? onSend : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _canSendNow ? p.lime : p.surface,
                        shape: BoxShape.circle,
                        boxShadow: _canSendNow
                            ? [BoxShadow(
                                color: p.lime.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              )]
                            : null,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: _canSendNow ? Colors.black : p.textSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small icon button ──────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _IconBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 36, height: 36, child: Center(child: child)),
    );
  }
}

// ── Image source tile ─────────────────────────────────────────────────────────

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.borderCard),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: p.lime.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(icon, color: p.lime, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label,
              style: GoogleFonts.poppins(
                color: p.textPri, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Pending image preview ─────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _ImagePreview({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final p = ChatThemeScope.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(path), width: 72, height: 72, fit: BoxFit.cover),
          ),
          Positioned(
            top: -6, right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: p.isDark ? Colors.black : p.surfaceEl,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.border, width: 1.5),
                ),
                child: Icon(Icons.close_rounded, size: 12, color: p.textPri),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generate Plan FAB ─────────────────────────────────────────────────────────

class _GeneratePlanFab extends StatelessWidget {
  final VoidCallback onTap;
  const _GeneratePlanFab({required this.onTap});

  static const _kLime = Color(0xFFCCFF00);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _kLime,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _kLime.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(
              'Generate My Plan',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

// ── Plan generation bottom sheet ───────────────────────────────────────────────

enum _PlanSheetState { generating, success, error }

class _PlanGenerationSheet extends StatefulWidget {
  final String conversation;
  final OnboardingData? onboardingData;

  const _PlanGenerationSheet({
    required this.conversation,
    this.onboardingData,
  });

  @override
  State<_PlanGenerationSheet> createState() => _PlanGenerationSheetState();
}

class _PlanGenerationSheetState extends State<_PlanGenerationSheet> {
  static const _kLime     = Color(0xFFCCFF00);
  static const _kSurface  = Color(0xFF1A2332);
  static const _kCard     = Color(0xFF0A0C12);
  static const _kBorder   = Color(0xFF2A2F3D);
  static const _kTextSub  = Color(0xFF9E9E9E);

  _PlanSheetState _state = _PlanSheetState.generating;
  String? _errorMessage;
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _startProgress();
    _generate();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startProgress() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      setState(() {
        if (_progress < 0.9) {
          _progress += (0.9 - _progress) * 0.04;
        } else if (_progress < 0.95) {
          _progress += 0.008;
        }
      });
    });
  }

  void _stopProgress() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> _generate() async {
    final data = widget.onboardingData;
    final workoutDays = data?.workoutDays ?? 3;
    try {
      final raw = await ChatPlanService().generateFromChat(
        conversation:  widget.conversation,
        goal:          data?.goal ?? '',
        gender:        data?.gender ?? '',
        height:        data?.height ?? '',
        weight:        data?.weight ?? '',
        experience:    data?.experience ?? '',
        duration:      '12 weeks',
        trainingSplit: '$workoutDays days/week',
      );

      final plan = WorkoutPlanModel.fromJson(raw);

      // Save to DB
      await sl<SaveFitnessPlanUsecase>()(
        workoutPlan: plan,
        imageFilePath: null,
      );

      _stopProgress();
      if (mounted) {
        setState(() {
          _progress = 1.0;
          _state = _PlanSheetState.success;
        });
      }
    } catch (e) {
      _stopProgress();
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
          _state = _PlanSheetState.error;
        });
      }
    }
  }

  double get _sheetHeight => _state == _PlanSheetState.success ? 0.55 : 0.42;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      height: MediaQuery.of(context).size.height * _sheetHeight,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _kBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      _PlanSheetState.generating => _buildGenerating(),
      _PlanSheetState.success    => _buildSuccess(),
      _PlanSheetState.error      => _buildError(),
    };
  }

  Widget _buildGenerating() {
    final pct = (_progress * 100).toInt();
    final label = _progress < 0.3
        ? 'Reading your conversation…'
        : _progress < 0.6
            ? 'Designing your programme…'
            : _progress < 0.9
                ? 'Building weekly schedule…'
                : 'Finalising details…';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$pct%',
          style: GoogleFonts.poppins(
            color: _kLime, fontSize: 52,
            fontWeight: FontWeight.w700, letterSpacing: -1),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _progress, minHeight: 5,
            backgroundColor: _kSurface,
            valueColor: const AlwaysStoppedAnimation<Color>(_kLime),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Generating your personalised plan…',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(label,
          style: GoogleFonts.inter(color: _kTextSub, fontSize: 12)),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3), width: 1.5),
          ),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF4CAF50), size: 32),
        ),
        const SizedBox(height: 16),
        Text('Plan Ready! 🎉',
          style: GoogleFonts.poppins(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Your personalised workout plan has been\ncreated and saved to your profile.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: _kTextSub, fontSize: 13, height: 1.55)),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            context.go('/home');
          },
          child: Container(
            width: double.infinity, height: 54,
            decoration: BoxDecoration(
              color: _kLime,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _kLime.withValues(alpha: 0.3),
                  blurRadius: 18, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center_rounded,
                    color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Text('View My Plan',
                  style: GoogleFonts.poppins(
                    color: Colors.black, fontSize: 15,
                    fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 48, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(
          'Could not generate your plan',
          style: GoogleFonts.poppins(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Check your connection and try again.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: _kTextSub, fontSize: 12, height: 1.5)),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Center(
                    child: Text('Cancel',
                      style: GoogleFonts.poppins(
                        color: _kTextSub, fontSize: 13,
                        fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _state = _PlanSheetState.generating;
                    _progress = 0.0;
                  });
                  _startProgress();
                  _generate();
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _kLime,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text('Retry',
                      style: GoogleFonts.poppins(
                        color: Colors.black, fontSize: 13,
                        fontWeight: FontWeight.w700)),
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

// ── Reconnect banner ──────────────────────────────────────────────────────────

class _ReconnectBanner extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  const _ReconnectBanner({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.red.shade900.withValues(alpha: 0.9),
      child: Row(
        children: [
          const Icon(Icons.signal_wifi_off_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error ?? 'Disconnected from coach',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text('Retry',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
