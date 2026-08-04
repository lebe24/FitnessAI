import 'package:fitness/data/services/motivation/motivation_schedule_storage.dart';
import 'package:fitness/ui/features/fitness/view_models/motivation_view_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kLime     = Color(0xFFCCFF00);
const _kCard     = Color(0xFF111318);
const _kBorder   = Color(0xFF1E2330);
const _kDimWhite = Color(0x80FFFFFF);

/// Step 2 of the motivation flow: when should the daily message arrive?
///
/// Opened after a tone is chosen. On confirm it asks the backend for AI copy
/// in that tone and schedules a week of local notifications.
class MotivationScheduleSheet extends StatefulWidget {
  final String tone;
  final MotivationViewModel vm;

  const MotivationScheduleSheet({
    super.key,
    required this.tone,
    required this.vm,
  });

  @override
  State<MotivationScheduleSheet> createState() =>
      _MotivationScheduleSheetState();
}

class _MotivationScheduleSheetState extends State<MotivationScheduleSheet> {
  MotivationSlot _slot = MotivationSlot.morning;
  TimeOfDay _custom = const TimeOfDay(hour: 6, minute: 30);
  bool _busy = false;

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _custom,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kLime,
            onPrimary: Colors.black,
            surface: _kCard,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _custom = picked;
        _slot = MotivationSlot.custom;
      });
    }
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final result = await widget.vm.enable(
      tone: widget.tone,
      slot: _slot,
      hour: _slot == MotivationSlot.custom ? _custom.hour : null,
      minute: _slot == MotivationSlot.custom ? _custom.minute : null,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    switch (result) {
      case MotivationSetupResult.success:
        messenger.showSnackBar(SnackBar(
          content: Text("You're set — your coach will check in daily.",
              style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: const Color(0xFF1A2A00),
          behavior: SnackBarBehavior.floating,
        ));
      case MotivationSetupResult.permissionDenied:
        messenger.showSnackBar(SnackBar(
          content: Text('Enable notifications in Settings to get motivation.',
              style: GoogleFonts.inter(fontSize: 13)),
          behavior: SnackBarBehavior.floating,
        ));
      case MotivationSetupResult.noMessages:
        messenger.showSnackBar(SnackBar(
          content: Text("Couldn't reach your coach — try again shortly.",
              style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(Icons.notifications_active_rounded,
                      color: _kLime, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('When should we push you?',
                          style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('${widget.tone} · daily',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: _kLime)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              _SlotOption(
                icon: Icons.wb_twilight_rounded,
                label: 'Morning',
                subtitle: 'Start the day fired up · 7:00 AM',
                isSelected: _slot == MotivationSlot.morning,
                onTap: () => setState(() => _slot = MotivationSlot.morning),
              ),
              const SizedBox(height: 10),
              _SlotOption(
                icon: Icons.nights_stay_rounded,
                label: 'Evening',
                subtitle: 'A nudge when willpower dips · 6:00 PM',
                isSelected: _slot == MotivationSlot.evening,
                onTap: () => setState(() => _slot = MotivationSlot.evening),
              ),
              const SizedBox(height: 10),
              _SlotOption(
                icon: Icons.schedule_rounded,
                label: 'Custom time',
                subtitle: _slot == MotivationSlot.custom
                    ? _custom.format(context)
                    : 'Pick your own moment',
                isSelected: _slot == MotivationSlot.custom,
                onTap: _pickCustomTime,
                trailingChevron: true,
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _busy ? null : _confirm,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _busy ? Colors.white.withValues(alpha: 0.06) : _kLime,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: _busy
                        ? null
                        : [BoxShadow(
                            color: _kLime.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: _busy
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kLime),
                          )
                        : Text('Start motivating me',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Your coach writes each message from your goal, stats and streak.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.35)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool trailingChevron;

  const _SlotOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.trailingChevron = false,
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
          Icon(icon, size: 19, color: isSelected ? _kLime : Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? _kLime : Colors.white,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 11, color: _kDimWhite)),
              ],
            ),
          ),
          if (trailingChevron && !isSelected)
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.25), size: 20)
          else
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
