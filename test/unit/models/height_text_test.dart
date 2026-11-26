import 'package:fitness/domain/models/height_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toCm reads every format the app has written', () {
    test('centimetres', () => expect(HeightText.toCm('178 cm'), 178));
    test('onboarding metres', () => expect(HeightText.toCm('1.8 m'), closeTo(180, 0.001)));
    test('onboarding feet and inches', () => expect(HeightText.toCm('5 ft 10 in'), closeTo(177.8, 0.01)));
    test('the old Adjust decimal feet', () => expect(HeightText.toCm('5.9 ft'), closeTo(179.8, 0.1)));
    test('feet with an apostrophe', () {
      expect(HeightText.toCm("5'11"), closeTo(180.34, 0.01));
      expect(HeightText.toCm('5’11"'), closeTo(180.34, 0.01));
    });
    test('feet only', () => expect(HeightText.toCm('6 ft'), closeTo(182.88, 0.01)));
    test('inches only', () => expect(HeightText.toCm('70 in'), closeTo(177.8, 0.01)));
    test('a bare number is centimetres if big, metres if small', () {
      expect(HeightText.toCm('175'), 175);
      expect(HeightText.toCm('1.75'), closeTo(175, 0.001));
    });
    test('not a height', () {
      expect(HeightText.toCm(null), isNull);
      expect(HeightText.toCm(''), isNull);
      expect(HeightText.toCm('tall'), isNull);
      expect(HeightText.toCm('12'), isNull);
    });
  });

  group('isImperial', () {
    test('feet and inches are imperial, the rest are not', () {
      expect(HeightText.isImperial('5 ft 10 in'), isTrue);
      expect(HeightText.isImperial('5.9 ft'), isTrue);
      expect(HeightText.isImperial("5'10"), isTrue);
      expect(HeightText.isImperial('70 in'), isTrue);
      expect(HeightText.isImperial('178 cm'), isFalse);
      expect(HeightText.isImperial('1.8 m'), isFalse);
      expect(HeightText.isImperial(null), isFalse);
    });
  });

  group('feet and inches', () {
    test('round trip through centimetres', () {
      expect(HeightText.feetInches(HeightText.fromFeetInches(5, 10)), (5, 10));
      expect(HeightText.feetInches(HeightText.fromFeetInches(6, 0)), (6, 0));
    });

    test('inches carry into a foot instead of reading 12', () {
      // 5 ft 11.6 in rounds to 6 ft 0 in.
      expect(HeightText.feetInches(HeightText.fromFeetInches(5, 11) + 1.5), (6, 0));
    });

    test('178 cm is 5 ft 10 in', () => expect(HeightText.feetInches(178), (5, 10)));
  });

  test('stored formats match onboarding', () {
    expect(HeightText.storedImperial(5, 10), '5 ft 10 in');
    expect(HeightText.storedMetric(178), '178 cm');
    expect(HeightText.storedMetric(178.5), '178.5 cm');
  });
}
