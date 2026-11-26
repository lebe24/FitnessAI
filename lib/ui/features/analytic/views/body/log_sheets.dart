import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:flutter/material.dart';

/// Log a weigh-in.
class LogWeightSheet extends StatefulWidget {
  /// The most recent weight, shown as a hint and used to catch a slip of the finger.
  final double? lastKg;
  final bool imperial;
  final ValueChanged<bool> onUnitChanged;

  /// Saves the weight in kilograms. Returns whether it was accepted.
  final Future<bool> Function(double kg, DateTime date, String? note) onSave;

  const LogWeightSheet({
    super.key,
    required this.lastKg,
    required this.imperial,
    required this.onUnitChanged,
    required this.onSave,
  });

  @override
  State<LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<LogWeightSheet> {
  final _weight = TextEditingController();
  final _note = TextEditingController();
  late bool _imperial = widget.imperial;
  DateTime _date = DateTime.now();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  /// A weight more than 15 kg from the last one is more likely a typo.
  double? _kg() {
    final v = parseNumber(_weight.text);
    if (v == null) return null;
    return _imperial ? BodyUnits.lbToKg(v) : v;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: kBodyLime, onPrimary: Colors.black, surface: kBodyCard),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final kg = _kg();
    if (kg == null) {
      setState(() => _error = 'Enter your weight as a number.');
      return;
    }
    if (kg < 20 || kg > 400) {
      setState(() => _error = 'That does not look like a body weight. Check the number and unit.');
      return;
    }
    final last = widget.lastKg;
    if (last != null && (kg - last).abs() > 15 && _error == null) {
      setState(() => _error =
          'That is ${BodyUnits.weight((kg - last).abs(), imperial: _imperial)} from your last weigh-in. '
          'Tap Save again if it is right.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final note = _note.text.trim();
    final ok = await widget.onSave(kg, _date, note.isEmpty ? null : note);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = 'Could not save that weight.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = _date.year == today.year && _date.month == today.month && _date.day == today.day;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Row(
            children: [
              Expanded(child: Text('Log your weight', style: bodyHeading(20))),
              UnitToggle(
                imperial: _imperial,
                onChanged: (v) {
                  // Keep the number the person typed meaning the same weight.
                  final typed = parseNumber(_weight.text);
                  if (typed != null && v != _imperial) {
                    final kg = _imperial ? BodyUnits.lbToKg(typed) : typed;
                    final shown = v ? BodyUnits.kgToLb(kg) : kg;
                    _weight.text = shown.toStringAsFixed(1);
                  }
                  setState(() => _imperial = v);
                  widget.onUnitChanged(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          BodyField(
            controller: _weight,
            label: 'Weight',
            suffix: _imperial ? 'lb' : 'kg',
            hint: widget.lastKg == null
                ? null
                : (_imperial ? BodyUnits.kgToLb(widget.lastKg!) : widget.lastKg!).toStringAsFixed(1),
            autofocus: true,
            error: _error,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: kBodyBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBodyBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: kBodyMuted),
                  const SizedBox(width: 10),
                  Text(isToday ? 'Today' : shortDate(_date), style: bodyText(14, weight: FontWeight.w600)),
                  const Spacer(),
                  Text('Change', style: bodyText(12, color: kBodyLime, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          BodyField(
            controller: _note,
            label: 'Note (optional)',
            keyboard: TextInputType.text,
          ),
          const SizedBox(height: 8),
          Text('A second weigh-in on the same day replaces the first.', style: bodyText(11.5, color: kBodyMuted)),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: BodyButton(label: 'Save', busy: _busy, onPressed: _save)),
        ],
      ),
    );
  }
}

/// Log tape measurements. Only the fields filled in are saved.
class LogMeasurementsSheet extends StatefulWidget {
  /// Latest reading per site in centimetres, shown as hints.
  final Map<MeasurementSite, double> latestCm;
  final bool imperial;
  final ValueChanged<bool> onUnitChanged;

  /// Saves readings in centimetres taken on [date]. Returns how many were saved.
  final Future<int> Function(Map<MeasurementSite, double> cm, DateTime date) onSave;

  const LogMeasurementsSheet({
    super.key,
    required this.latestCm,
    required this.imperial,
    required this.onUnitChanged,
    required this.onSave,
  });

  @override
  State<LogMeasurementsSheet> createState() => _LogMeasurementsSheetState();
}

class _LogMeasurementsSheetState extends State<LogMeasurementsSheet> {
  static const _groups = <String, List<MeasurementSite>>{
    'Upper body': [MeasurementSite.chest, MeasurementSite.shoulders, MeasurementSite.neck, MeasurementSite.waist, MeasurementSite.hips],
    'Arms': [MeasurementSite.bicepL, MeasurementSite.bicepR, MeasurementSite.forearmL, MeasurementSite.forearmR],
    'Legs': [MeasurementSite.thighL, MeasurementSite.thighR, MeasurementSite.calfL, MeasurementSite.calfR],
  };

  late final Map<MeasurementSite, TextEditingController> _c = {
    for (final s in MeasurementSite.values) s: TextEditingController(),
  };
  late bool _imperial = widget.imperial;
  final Map<MeasurementSite, String> _errors = {};
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final out = <MeasurementSite, double>{};
    _errors.clear();
    for (final e in _c.entries) {
      final text = e.value.text.trim();
      if (text.isEmpty) continue;
      final v = parseNumber(text);
      final cm = v == null ? null : (_imperial ? BodyUnits.inToCm(v) : v);
      if (cm == null || cm < 5 || cm > 250) {
        _errors[e.key] = 'Check this';
      } else {
        out[e.key] = cm;
      }
    }
    if (_errors.isNotEmpty) {
      setState(() => _message = 'Some readings are not possible. Check the highlighted ones.');
      return;
    }
    if (out.isEmpty) {
      setState(() => _message = 'Enter at least one measurement.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final saved = await widget.onSave(out, DateTime.now());
    if (!mounted) return;
    if (saved > 0) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _message = 'Nothing was saved.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Row(
            children: [
              Expanded(child: Text('Log measurements', style: bodyHeading(20))),
              UnitToggle(
                imperial: _imperial,
                metric: 'cm',
                imperialLabel: 'in',
                onChanged: (v) {
                  setState(() => _imperial = v);
                  widget.onUnitChanged(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Measure relaxed, at the same spot each time. Fill in only what you measured.',
              style: bodyText(12.5, color: kBodyMuted, height: 1.45)),
          for (final g in _groups.entries) ...[
            const SizedBox(height: 18),
            Text(g.key.toUpperCase(),
                style: bodyText(10.5, color: kBodyMuted, weight: FontWeight.w800).copyWith(letterSpacing: 1)),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, c) {
              final w = (c.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final s in g.value)
                    SizedBox(
                      width: w,
                      child: BodyField(
                        controller: _c[s]!,
                        label: s.label,
                        suffix: _imperial ? 'in' : 'cm',
                        hint: widget.latestCm[s] == null
                            ? null
                            : (_imperial ? BodyUnits.cmToIn(widget.latestCm[s]!) : widget.latestCm[s]!)
                                .toStringAsFixed(1),
                        error: _errors[s],
                        onChanged: (_) => setState(() {
                          _errors.remove(s);
                          _message = null;
                        }),
                      ),
                    ),
                ],
              );
            }),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: bodyText(12.5, color: kBodyRed)),
          ],
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: BodyButton(label: 'Save', busy: _busy, onPressed: _save)),
        ],
      ),
    );
  }
}
