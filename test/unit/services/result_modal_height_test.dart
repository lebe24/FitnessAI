import 'package:fitness/ui/features/home/views/result_modal.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Extra Info sheet asks for 420pt and sits at the bottom of the screen.
/// A software keyboard is around 340pt, so it covered the field the user was
/// typing into — they could not read their own text.
///
/// Numbers below are real device metrics, because the bug only appears at
/// particular ones: it is invisible on a tall phone in a test that invents a
/// 2000pt screen.
void main() {
  const inputSheet = 420.0;

  group('with the keyboard down', () {
    test('the sheet gets the height it asked for', () {
      // iPhone 15 Pro: 852pt tall, 59pt of notch.
      expect(
        ResultModalPage.visibleHeight(
          preferred: inputSheet,
          screenHeight: 852,
          topInset: 59,
          keyboardInset: 0,
        ),
        inputSheet,
      );
    });

    test('a tall state is not shrunk when there is room for it', () {
      // The success state wants 680pt and fits on a large phone.
      expect(
        ResultModalPage.visibleHeight(
          preferred: 680,
          screenHeight: 932,
          topInset: 62,
          keyboardInset: 0,
        ),
        680,
      );
    });
  });

  group('with the keyboard up', () {
    test('the sheet shrinks to what is left above it', () {
      // 852 - 59 - 336 - 32 = 425, so 420 still fits and stays whole.
      final h = ResultModalPage.visibleHeight(
        preferred: inputSheet,
        screenHeight: 852,
        topInset: 59,
        keyboardInset: 336,
      );
      expect(h, inputSheet);
      expect(h + 336, lessThan(852), reason: 'sheet and keyboard must both fit');
    });

    test('on a small phone it gives up height rather than the screen', () {
      // iPhone SE: 667pt, 20pt status bar, ~260pt keyboard.
      final h = ResultModalPage.visibleHeight(
        preferred: inputSheet,
        screenHeight: 667,
        topInset: 20,
        keyboardInset: 260,
      );
      expect(h, lessThan(inputSheet), reason: '420 cannot fit, so it must clamp');
      expect(h + 260, lessThanOrEqualTo(667 - 20),
          reason: 'the sheet must never be pushed off the top');
    });

    test('the tallest state clamps hard rather than overflowing', () {
      final h = ResultModalPage.visibleHeight(
        preferred: 680,
        screenHeight: 852,
        topInset: 59,
        keyboardInset: 336,
      );
      expect(h, lessThan(680));
      expect(h + 336 + 59, lessThanOrEqualTo(852));
    });
  });

  test('an absurd keyboard yields zero, never a negative height', () {
    // A negative height throws in the render tree; clamping to zero does not.
    expect(
      ResultModalPage.visibleHeight(
        preferred: inputSheet,
        screenHeight: 400,
        topInset: 59,
        keyboardInset: 380,
      ),
      0.0,
    );
  });
}
