import 'package:fitness/data/services/energy/energy_coach_service.dart';
import 'package:fitness/domain/energy/bot_settings.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/energy/view_models/energy_chat_controller.dart';
import 'package:fitness/ui/features/energy/views/bot_mascot.dart';
import 'package:fitness/ui/features/energy/views/energy_widgets.dart';
import 'package:flutter/material.dart';

/// Opens the pop-up chat about one session's energy.
Future<void> showEnergyChat(
  BuildContext context, {
  required EnergyFacts facts,
  required EnergyResponder responder,
  BotSettings bot = const BotSettings(),
  List<String> ask = const [],
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      // The sheet's own context, so it can lift itself above the keyboard.
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: EnergyChatSheet(facts: facts, responder: responder, bot: bot, ask: ask),
        ),
      ),
    );

/// The chat itself, with the mascot sitting on the top edge.
class EnergyChatSheet extends StatefulWidget {
  final EnergyFacts facts;
  final EnergyResponder responder;
  final BotSettings bot;

  /// Questions asked automatically once the estimate shows. For previews.
  final List<String> ask;

  const EnergyChatSheet({
    super.key,
    required this.facts,
    required this.responder,
    this.bot = const BotSettings(),
    this.ask = const [],
  });

  @override
  State<EnergyChatSheet> createState() => _EnergyChatSheetState();
}

class _EnergyChatSheetState extends State<EnergyChatSheet> {
  late final _chat = EnergyChatController(
      facts: widget.facts, responder: widget.responder, botName: widget.bot.name);
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final List<String> _queued = List.of(widget.ask);

  @override
  void initState() {
    super.initState();
    _chat.addListener(_changed);
    _chat.start();
  }

  void _changed() {
    if (_queued.isNotEmpty && _chat.estimate != null && !_chat.typing) {
      final next = _queued.removeAt(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _chat.send(next);
      });
    }
    // Keeps the newest message in view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    });
  }

  void _send() {
    if (_chat.send(_input.text)) _input.clear();
  }

  @override
  void dispose() {
    _chat.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // With the keyboard up on a small phone, the mascot makes room.
        final compact = box.maxHeight < 480;
        return ListenableBuilder(
          listenable: _chat,
          builder: (context, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: compact ? 0 : 52,
                child: Material(
                  color: kBodyBg,
                  clipBehavior: Clip.antiAlias,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    side: BorderSide(color: kBodyBorder),
                  ),
                  child: Column(
                    children: [
                      _Header(
                          name: widget.bot.name,
                          session: widget.facts.session.title,
                          compact: compact),
                      Expanded(
                        child: ListView(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          children: [
                            for (final m in _chat.messages)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: switch (m) {
                                  BotText(:final text, :final offline) => SpeechBubble(text,
                                      note: offline ? 'Quick answer · couldn\'t reach the coach' : null),
                                  UserText(:final text) => SpeechBubble(text, fromUser: true),
                                  EnergyResult(:final estimate) => EnergyResultCard(
                                      estimate: estimate, imperial: widget.facts.imperial),
                                },
                              ),
                            if (_chat.typing) ThinkingLine(widget.bot.name),
                          ],
                        ),
                      ),
                      _Replies(chat: _chat),
                      _Composer(controller: _input, chat: _chat, name: widget.bot.name, onSend: _send),
                    ],
                  ),
                ),
              ),
              if (!compact)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: PopIn(
                      alignment: Alignment.bottomCenter,
                      child: BotMascotView(
                          mascot: widget.bot.mascot,
                          size: 108,
                          mood: _chat.mood,
                          semanticLabel: widget.bot.name),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String session;
  final bool compact;
  const _Header({required this.name, required this.session, required this.compact});

  @override
  Widget build(BuildContext context) {
    // The same square button the app's pages use to go back.
    final close = Semantics(
      button: true,
      label: 'Close',
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBodyBorder),
          ),
          child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
        ),
      ),
    );
    final title = Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyHeading(18));

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
        child: Row(children: [Expanded(child: title), close]),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // Room for the mascot, which sits across the top edge.
          SizedBox(height: 46, child: Align(alignment: Alignment.topRight, child: close)),
          title,
          const SizedBox(height: 2),
          Text('Your energy bot · $session',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyText(12, color: kBodyMuted)),
        ],
      ),
    );
  }
}

/// Durations while asking for one, suggested questions afterwards.
class _Replies extends StatelessWidget {
  final EnergyChatController chat;
  const _Replies({required this.chat});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (chat.waitingFor == EnergyQuestion.duration && !chat.typing)
        for (final m in EnergyChatController.durationChoices)
          ReplyChip(label: '$m min', onTap: () => chat.pickMinutes(m)),
      for (final q in chat.openSuggestions) ReplyChip(label: q, onTap: () => chat.send(q)),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    // One scrolling row keeps the conversation tall.
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: chips[i]),
      ),
    );
  }
}

/// The input card and round send button of the coach chat.
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final EnergyChatController chat;
  final String name;
  final VoidCallback onSend;
  const _Composer({
    required this.controller,
    required this.chat,
    required this.name,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final hint = switch (chat.waitingFor) {
      EnergyQuestion.duration => 'Type your minutes…',
      EnergyQuestion.weight => 'Type your weight in ${chat.facts.imperial ? 'lb' : 'kg'}…',
      EnergyQuestion.none => 'Ask $name…',
    };
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
          decoration: BoxDecoration(
            color: const Color(0xFF121620),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2A2F3D)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onSend(),
                  textInputAction: TextInputAction.send,
                  keyboardType: chat.waitingFor == EnergyQuestion.none
                      ? TextInputType.text
                      : const TextInputType.numberWithOptions(decimal: true),
                  maxLength: 300,
                  style: bodyText(15),
                  cursorColor: kBodyLime,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: bodyText(15, color: kBodyMuted),
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: controller,
                builder: (_, __) {
                  final ready = controller.text.trim().isNotEmpty && !chat.typing;
                  return Semantics(
                    button: true,
                    enabled: ready,
                    label: 'Send',
                    child: GestureDetector(
                      onTap: ready ? onSend : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ready ? kBodyLime : const Color(0xFF1A2332),
                          shape: BoxShape.circle,
                          boxShadow: ready
                              ? [
                                  BoxShadow(
                                    color: kBodyLime.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(Icons.arrow_upward_rounded,
                            size: 18, color: ready ? Colors.black : kBodyMuted),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
