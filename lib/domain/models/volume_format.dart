import 'package:fitness/domain/body/body_models.dart';
import 'package:intl/intl.dart';

/// Training load as text in the user's unit. Storage is always kilograms; this
/// is display only.
///
/// Volume is a big number, so it gets separators and no decimals: `9,420 kg`.
String formatVolume(double kg, {required bool imperial}) {
  final v = imperial ? BodyUnits.kgToLb(kg) : kg;
  return '${_thousands.format(v.round())} ${imperial ? 'lb' : 'kg'}';
}

/// A short total for tight spots such as a chart header: `12.3t` or `810 kg`,
/// and in pounds `27.2k lb` or `810 lb`.
String formatVolumeShort(double kg, {required bool imperial}) {
  if (!imperial) {
    return kg >= 1000 ? '${(kg / 1000).toStringAsFixed(1)}t' : '${kg.round()} kg';
  }
  final lb = BodyUnits.kgToLb(kg);
  return lb >= 1000 ? '${(lb / 1000).toStringAsFixed(1)}k lb' : '${lb.round()} lb';
}

/// The weight on one set: `60 kg`, `62.5 kg`, `132.3 lb`. One decimal at most,
/// and no `.0`.
String formatSetWeight(double kg, {required bool imperial}) =>
    BodyUnits.weight(kg, imperial: imperial);

final _thousands = NumberFormat('#,##0', 'en_US');
