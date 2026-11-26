import 'package:fitness/domain/models/volume_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatVolume', () {
    test('adds thousands separators and drops decimals', () {
      expect(formatVolume(9420, imperial: false), '9,420 kg');
      expect(formatVolume(9420.4, imperial: false), '9,420 kg');
      expect(formatVolume(9420.6, imperial: false), '9,421 kg');
    });

    test('small and zero loads', () {
      expect(formatVolume(810, imperial: false), '810 kg');
      expect(formatVolume(0, imperial: false), '0 kg');
    });

    test('converts to pounds', () {
      expect(formatVolume(1000, imperial: true), '2,205 lb');
      expect(formatVolume(100, imperial: true), '220 lb');
    });

    test('large loads keep the separator', () {
      expect(formatVolume(1234567, imperial: false), '1,234,567 kg');
    });
  });

  group('formatVolumeShort', () {
    test('tonnes for heavy metric loads, kilograms below', () {
      expect(formatVolumeShort(12345, imperial: false), '12.3t');
      expect(formatVolumeShort(810, imperial: false), '810 kg');
    });

    test('thousands of pounds, and pounds below', () {
      expect(formatVolumeShort(12345, imperial: true), '27.2k lb');
      expect(formatVolumeShort(100, imperial: true), '220 lb');
    });
  });

  group('formatSetWeight', () {
    test('trims a trailing .0 and keeps one decimal', () {
      expect(formatSetWeight(60, imperial: false), '60 kg');
      expect(formatSetWeight(62.5, imperial: false), '62.5 kg');
    });

    test('converts to pounds', () {
      expect(formatSetWeight(60, imperial: true), '132.3 lb');
    });
  });
}
