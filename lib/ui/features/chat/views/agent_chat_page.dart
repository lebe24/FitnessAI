import 'dart:io';

import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/ui/core/constants/assets.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/chat/view_models/chat_view_model.dart';
import 'package:fitness/ui/features/chat/views/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

const _suggestions = [
  ("💪", "Show me my workout plan"),
  ("🥗", "What should I eat to lose fat?"),
  ("🔥", "How is my progress? z"),
  ("📈", "How do I improve my running pace?"),
];

class AgentChatPage extends StatefulWidget {
  final VoidCallback? onBack;
  const AgentChatPage({super.key, this.onBack});

  @override
  State<AgentChatPage> createState() => _AgentChatPageState();
}

class _AgentChatPageState extends State<AgentChatPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ChatViewModel _vm;
  final _textController   = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode        = FocusNode();
  final _picker           = ImagePicker();
  bool    _hasText          = false;
  String? _pendingImagePath;
  bool    _isDark           = true;
  bool    _disposed         = false;

  String get _userName {
    final user = sl<GetCurrentUser>()();
    return user?.email?.split('@').first ?? 'there';
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _vm = sl<ChatViewModel>(instanceName: 'agent');
    _vm.addListener(_onVmChange);
    _connectChat();
  }

  Future<void> _connectChat() async {
    final user = sl<GetCurrentUser>()();
    if (user == null || _disposed) return;
    // Context is loaded server-side from the DB — just pass userId.
    await _vm.connect(user.id, user.email ?? 'User');
  }

  void _onTextChanged() {
    final has = _textController.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _onVmChange() {
    if (!mounted || _disposed) return;
    setState(() {});
    if (_vm.messages.isNotEmpty) _scrollToBottom();
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

  void _send([String? preset]) {
    final text  = preset ?? _textController.text.trim();
    final image = _pendingImagePath;
    if (text.isEmpty && image == null) return;
    final user = sl<GetCurrentUser>()();
    if (user == null) return;
    if (preset == null) _textController.clear();
    setState(() => _pendingImagePath = null);
    _vm.sendMessage(
      text.isEmpty ? '📷 [image attached]' : text,
      user.id,
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
    } catch (_) {
      
    }
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
                        color: p.textPri,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _SourceTile(
                    icon: Icons.camera_alt_rounded, label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SourceTile(
                    icon: Icons.photo_library_rounded, label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleTheme() => setState(() => _isDark = !_isDark);

  @override
  void dispose() {
    _disposed = true;
    _textController.removeListener(_onTextChanged);
    _vm.removeListener(_onVmChange);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ChangeNotifierProvider<ChatViewModel>.value(
      value: _vm,
      child: Consumer<ChatViewModel>(
        builder: (context, vm, _) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _isDark ? 0.0 : 1.0),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOut,
            builder: (context, t, _) {
              final p =
                  ChatPalette.lerp(ChatPalette.dark, ChatPalette.light, t);

              return ChatThemeScope(
                palette: p,
                child: Scaffold(
                  backgroundColor: p.bg,
                  appBar: _AppBar(
                    vm: vm,
                    isDark: _isDark,
                    onBack: widget.onBack,
                    onClear: vm.clearMessages,
                    onToggleTheme: _toggleTheme,
                  ),
                  body: Column(children: [
                    if (!vm.isConnected && !vm.isConnecting)
                      _ReconnectBanner(
                        error: vm.error,
                        onRetry: _connectChat,
                      ),

                    Expanded(
                      child: vm.isConnecting
                          ? _ConnectingView()
                          : vm.messages.isEmpty
                              ? _EmptyView(
                                  userName: _userName,
                                  onSuggestion: _send,
                                )
                              : GestureDetector(
                                  onTap: _focusNode.unfocus,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 20, 16, 8),
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
                      onClearImage: () =>
                          setState(() => _pendingImagePath = null),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatViewModel vm;
  final VoidCallback? onBack;
  final VoidCallback onClear;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const _AppBar({
    required this.vm,
    required this.isDark,
    required this.onClear,
    required this.onToggleTheme,
    this.onBack,
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
      leading: onBack != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: onBack,
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: p.textPri.withValues(alpha: 0.7), size: 18),
              ),
            )
          : null,
      title: Row(children: [
        
        Image.asset(ImagePath.appLogo, height: 32, fit: BoxFit.contain),
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
                    blurRadius: 6)]
                : null,
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
          child: Text('AI',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: p.limeText,
                  letterSpacing: 0.5)),
        ),
      ]),
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
              child: Row(children: [
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
                    alignment: isDark
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
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
              ]),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'clear',
              child: Row(children: [
                const Icon(Icons.delete_sweep_rounded,
                    color: Colors.redAccent, size: 16),
                const SizedBox(width: 10),
                Text('Clear chat',
                    style: GoogleFonts.inter(color: p.textPri, fontSize: 13)),
              ]),
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 32, height: 32,
          child: CircularProgressIndicator(
              color: p.lime, strokeWidth: 2, strokeCap: StrokeCap.round),
        ),
        const SizedBox(height: 16),
        Text('Connecting to your agent…',
            style: GoogleFonts.inter(color: p.textSub, fontSize: 13)),
      ]),
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
    final p = ChatThemeScope.of(context);
    final first = userName.split(' ').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
      child: Column(children: [
        Opacity(
          opacity: p.isDark ? 0.06 : 0.08,
          child: Image.asset(ImagePath.appLogo, width: 180, height: 180),
        ),

        const SizedBox(height: 28),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(children: [
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
          ]),
        ),

        const SizedBox(height: 10),

        Text(
          'Your AI fitness agent.\nAsk me anything about training, nutrition,\nor tracking your progress.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: p.textSub.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.65),
        ),

        const SizedBox(height: 36),

        Row(children: [
          Expanded(
              child: Divider(
                  color: p.border.withValues(alpha: 0.5), height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Try asking',
                style: GoogleFonts.inter(
                    color: p.textSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4)),
          ),
          Expanded(
              child: Divider(
                  color: p.border.withValues(alpha: 0.5), height: 1)),
        ]),

        const SizedBox(height: 16),

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
      ]),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.04, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _SuggestionChip extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _SuggestionChip(
      {required this.emoji, required this.label, required this.onTap});

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
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji,
              style: const TextStyle(
                fontSize: 14,
                inherit: false,
                fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji'],
              )),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: p.textPri.withValues(alpha: 0.6))),
        ]),
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
      child: Row(children: [
        Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: p.lime, shape: BoxShape.circle),
        ),
        Text('Agent is thinking…',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: p.textSub,
                fontStyle: FontStyle.italic)),
      ]),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 600.ms)
        .then()
        .fadeOut(duration: 600.ms);
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

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
    final p = ChatThemeScope.of(context);
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
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (pendingImage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: _ImagePreview(
                  path: pendingImage!, onRemove: onClearImage),
            ),

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
                    ? pendingImage != null
                        ? 'Add a caption…'
                        : 'Ask anything…'
                    : 'Not connected',
                hintStyle: GoogleFonts.inter(
                    color: p.textSub.withValues(alpha: 0.5), fontSize: 15),
                border: InputBorder.none,
                filled: false,
                contentPadding:
                    const EdgeInsets.fromLTRB(18, 14, 18, 8),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(children: [
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

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: p.lime.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.lime.withValues(alpha: 0.15)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 11,
                      color: p.limeText.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text('Agent',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: p.limeText.withValues(alpha: 0.6))),
                ]),
              ),

              const Spacer(),

              _IconBtn(
                onTap: canSend ? onAttach : null,
                child: Icon(Icons.camera_alt_rounded,
                    size: 18,
                    color: p.textSub.withValues(alpha: 0.5)),
              ),

              const SizedBox(width: 6),

              GestureDetector(
                onTap: _canSendNow ? onSend : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _canSendNow ? p.lime : p.surface,
                    shape: BoxShape.circle,
                    boxShadow: _canSendNow
                        ? [
                            BoxShadow(
                                color: p.lime.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 4))
                          ]
                        : null,
                  ),
                  child: Icon(Icons.arrow_upward_rounded,
                      size: 18,
                      color: _canSendNow ? Colors.black : p.textSub),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _IconBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(width: 36, height: 36, child: Center(child: child)),
      );
}

// ── Image source tile ─────────────────────────────────────────────────────────

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile(
      {required this.icon, required this.label, required this.onTap});

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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: p.lime.withValues(alpha: 0.10),
                shape: BoxShape.circle),
            child: Icon(icon, color: p.lime, size: 22),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: GoogleFonts.poppins(
                  color: p.textPri,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
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
      child: Stack(clipBehavior: Clip.none, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              Image.file(File(path), width: 72, height: 72, fit: BoxFit.cover),
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
      ]),
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
      child: Row(children: [
        const Icon(Icons.signal_wifi_off_rounded,
            color: Colors.white, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(error ?? 'Disconnected from agent',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
        GestureDetector(
          onTap: onRetry,
          child: Text('Retry',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white)),
        ),
      ]),
    );
  }
}
