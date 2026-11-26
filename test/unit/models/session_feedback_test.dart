import 'package:fitness/domain/models/session_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an empty or missing map is empty', () {
    expect(SessionFeedback.fromMap(null).isEmpty, isTrue);
    expect(SessionFeedback.fromMap(const {}).isEmpty, isTrue);
  });

  test('reads what the post-workout analysis saves', () {
    final f = SessionFeedback.fromMap({
      'session_analysis': ' Strong session. ',
      'performance_highlights': ['Bench up 2.5 kg', '', 'Squat depth'],
      'areas_to_improve': ['Rest too short'],
      'rest_feedback': 'Rest 90s.',
      'next_session_tip': 'Add a set.',
      'nutrition_advice': {
        'immediate': 'Eat within an hour.',
        'protein_target_g': 30,
        'meal_suggestions': ['Chicken and rice'],
        'hydration': '500 ml.',
        'timing_tip': 'Within 2 hours.',
      },
    });
    expect(f.isEmpty, isFalse);
    expect(f.analysis, 'Strong session.');
    expect(f.highlights, ['Bench up 2.5 kg', 'Squat depth']);
    expect(f.improvements, ['Rest too short']);
    expect(f.proteinTargetG, 30);
    expect(f.hasNutrition, isTrue);
  });

  test('wrong types and blanks are ignored rather than thrown on', () {
    final f = SessionFeedback.fromMap({
      'session_analysis': 5,
      'performance_highlights': 'not a list',
      'areas_to_improve': [1, null, 'ok'],
      'nutrition_advice': 'oops',
      'rest_feedback': '   ',
    });
    expect(f.analysis, isNull);
    expect(f.highlights, isEmpty);
    expect(f.improvements, ['ok']);
    expect(f.rest, isNull);
    expect(f.hasNutrition, isFalse);
  });

  test('a protein target of zero is not shown', () {
    expect(SessionFeedback.fromMap({'nutrition_advice': {'protein_target_g': 0}}).isEmpty, isTrue);
  });
}
