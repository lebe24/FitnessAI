import 'dart:io';
import 'package:fitness/ui/features/chat/view_models/chat_view_model.dart';
import 'package:fitness/ui/features/chat/views/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kLime    = Color(0xFFCCFF00);
const _kSurface = Color(0xFF0A0C12);
const _kCard    = Color(0xFF111318);
const _kBorder  = Color(0xFF1E2330);

// ── Quick-start prompts ────────────────────────────────────────────────────────
const _kSuggestions = [
  '💪  How\'s my form on this?',
  '🔥  What should I focus on?',
  '😓  I\'m feeling fatigued today',
  '📈  How do I progress this?',
];

Future<dynamic> chatModal({
  required BuildContext context,
  required ChatViewModel chatViewModel,
  required String userId,
  required VoidCallback onClose,
  required Function(String, {String? imagePath}) onSendMessage,
  required ScrollController scrollController,
  required TextEditingController messageController,
  required VoidCallback scrollToBottom,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (context) => ChangeNotifierProvider.value(
      value: chatViewModel,
      child: ChatThemeScope(
        palette: ChatPalette.dark,
        child: DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.5, 0.88, 0.95],
          builder: (context, _) => _ChatShell(
            userId: userId,
            onClose: onClose,
            onSendMessage: onSendMessage,
            scrollController: scrollController,
            messageController: messageController,
            scrollToBottom: scrollToBottom,
          ),
        ),
      ),
    ),
  );
}

// ── Main shell ─────────────────────────────────────────────────────────────────

class _ChatShell extends StatefulWidget {
  final String userId;
  final VoidCallback onClose;
  final Function(String, {String? imagePath}) onSendMessage;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final VoidCallback scrollToBottom;

  const _ChatShell({
    required this.userId,
    required this.onClose,
    required this.onSendMessage,
    required this.scrollController,
    required this.messageController,
    required this.scrollToBottom,
  });

  @override
  State<_ChatShell> createState() => _ChatShellState();
}

class _ChatShellState extends State<_ChatShell> {
  final _focusNode = FocusNode();
  final _picker    = ImagePicker();
  bool    _hasText          = false;
  String? _pendingImagePath;

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final has = widget.messageController.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _send([String? preset]) {
    final text  = preset ?? widget.messageController.text.trim();
    final image = _pendingImagePath;
    if (text.isEmpty && image == null) return;
    if (preset == null) widget.messageController.clear();
    setState(() => _pendingImagePath = null);
    widget.onSendMessage(
      text.isEmpty ? '📷 [image attached]' : text,
      imagePath: image,
    );
    widget.scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null && mounted) {
        setState(() => _pendingImagePath = picked.path);
        _focusNode.requestFocus();
      }
    } catch (_) {}
  }

  void _showImageSourceSheet() {
    final p = ChatPalette.dark;
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
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Attach an Image',
                  style: GoogleFonts.poppins(
                    color: p.textPri, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _SourceTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _SourceTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, vm, _) {
        return Container(
          decoration: const BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              _ChatHeader(onClose: widget.onClose),
              _ConnectionBadge(),
              Expanded(
                child: _MessageList(
                  scrollController: widget.scrollController,
                  scrollToBottom: widget.scrollToBottom,
                  onSuggestion: _send,
                ),
              ),
              if (vm.isSending) const _TypingIndicator(),
              _InputBar(
                controller: widget.messageController,
                focusNode: _focusNode,
                hasText: _hasText,
                canSend: vm.isConnected && !vm.isSending,
                isConnected: vm.isConnected,
                pendingImage: _pendingImagePath,
                onSend: _send,
                onAttach: _showImageSourceSheet,
                onClearImage: () => setState(() => _pendingImagePath = null),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _ChatHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              // AI indicator dot
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: _kLime,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kLime.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              Text(
                'BeFit Coach',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kLime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kLime.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'AI',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kLime,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onClose();
                },
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white38,
                    size: 17,
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

// ── Connection badge ───────────────────────────────────────────────────────────

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge();

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, vm, _) {
        if (vm.isConnecting) {
          return _badge(color: const Color(0xFFFFAA00),
              icon: Icons.sync_rounded, label: 'Connecting…', spinning: true);
        }
        if (vm.error != null) {
          return _badge(color: Colors.redAccent,
              icon: Icons.error_outline_rounded, label: vm.error!);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _badge({
    required Color color,
    required IconData icon,
    required String label,
    double iconSize = 12,
    bool spinning = false,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          spinning
              ? SizedBox(
                  width: 10, height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
              style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Message list ───────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final ScrollController scrollController;
  final VoidCallback scrollToBottom;
  final void Function(String) onSuggestion;

  const _MessageList({
    required this.scrollController,
    required this.scrollToBottom,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, vm, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
        if (vm.messages.isEmpty) {
          return _EmptyState(onSuggestion: onSuggestion);
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: vm.messages.length,
          itemBuilder: (context, i) =>
              ChatMessageBubble(message: vm.messages[i]),
        );
      },
    );
  }
}

// ── Empty / welcome state (Perplexity-inspired) ────────────────────────────────

class _EmptyState extends StatelessWidget {
  final void Function(String) onSuggestion;
  const _EmptyState({required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // ── Large watermark wordmark ──
          Text(
            'BeFit\nCoach',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 72,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.04),
              height: 0.9,
              letterSpacing: -2,
            ),
          ),

          const SizedBox(height: 24),

          // ── Subtitle ──
          Text(
            'Your AI Workout Advisor',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.35),
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Ask about form, fatigue, progression,\nor exercise substitutions.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),

          const SizedBox(height: 36),

          // ── Suggestion chips ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _kSuggestions
                .map((s) => _SuggestionChip(label: s, onTap: () => onSuggestion(s)))
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
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Typing indicator ────────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: _kLime, shape: BoxShape.circle),
          ),
          Text(
            'Coach is thinking…',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.35),
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
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 16),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Pending image preview ──────────────────────────────────
            if (pendingImage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: _ImagePreview(path: pendingImage!, onRemove: onClearImage),
              ),

            // ── Text input ─────────────────────────────────────────────
            TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: canSend,
              maxLines: null,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              cursorColor: _kLime,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: isConnected
                    ? pendingImage != null
                        ? 'Add a caption…'
                        : 'Ask anything…'
                    : 'Not connected',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              ),
            ),

            // ── Bottom action row ───────────────────────────────────────
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
                          ? _kLime
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // "Model" pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Coach',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Camera / image icon
                  _IconBtn(
                    onTap: canSend ? onAttach : null,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Send button — lime circle
                  GestureDetector(
                    onTap: _canSendNow ? onSend : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _canSendNow
                            ? _kLime
                            : Colors.white.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                        boxShadow: _canSendNow
                            ? [
                                BoxShadow(
                                  color: _kLime.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: _canSendNow
                            ? Colors.black
                            : Colors.white.withValues(alpha: 0.2),
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

// ── Image preview ──────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _ImagePreview({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path), width: 72, height: 72, fit: BoxFit.cover),
          ),
          Positioned(
            top: -6, right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBorder, width: 1.5),
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image source tile ──────────────────────────────────────────────────────────

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
                color: p.lime.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
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

// ── Custom dialog (preserved) ──────────────────────────────────────────────────

class CustomDialog extends StatelessWidget {
  const CustomDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300, height: 400,
      child: Card(
        color: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('This is a custom dialog',
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
