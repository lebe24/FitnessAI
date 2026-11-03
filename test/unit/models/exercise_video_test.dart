import 'package:fitness/domain/models/exercise_video.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({Map<String, dynamic>? over}) => {
      'exercise': 'conventional deadlift',
      'exercise_matches_request': true,
      'camera_view': 'rear',
      'confidence': 'low',
      'overall_score': 7,
      'stance_score': 8,
      'form_score': null,
      'tempo_score': 5,
      'summary': 'Stable set-up.',
      'reps': {'completed': 3, 'attempts': 4, 'notes': '4th stayed on the floor'},
      'stance': ['Hip-width feet'],
      'form': [],
      'tempo': ['Lift takes half a second'],
      'cues': [
        {'severity': 'high', 'issue': 'Bar dropped', 'fix': 'Lower it'}
      ],
      'good_points': ['Full lockout'],
      'limitations': ['Filmed from behind'],
      ...?over,
    };

void main() {
  group('FormAnalysis.fromJson', () {
    test('reads a full result, including the nulls', () {
      final a = FormAnalysis.fromJson(_json());
      expect(a.cameraView, CameraView.rear);
      expect(a.confidence, Confidence.low);
      expect(a.overallScore, 7);
      expect(a.formScore, isNull, reason: 'a score the model could not judge stays null');
      expect(a.repsCompleted, 3);
      expect(a.repAttempts, 4);
      expect(a.hadFailedAttempt, isTrue);
      expect(a.cues.single.severity, CueSeverity.high);
      expect(a.limitations, ['Filmed from behind']);
    });

    test('an empty object is all defaults, never an error', () {
      final a = FormAnalysis.fromJson({});
      expect(a.overallScore, isNull);
      expect(a.cameraView, CameraView.unclear);
      expect(a.confidence, Confidence.low);
      expect(a.cues, isEmpty);
      expect(a.exerciseMatchesRequest, isTrue);
    });

    test('wrong types are treated as missing', () {
      final a = FormAnalysis.fromJson(_json(over: {
        'overall_score': 'seven',
        'stance_score': 11,
        'form_score': 0,
        'tempo_score': 6.6,
        'camera_view': 'overhead',
        'confidence': 5,
        'reps': 'three',
        'stance': 'not a list',
        'cues': 'nope',
        'good_points': [1, 'real', null, '  '],
      }));
      expect(a.overallScore, isNull);
      expect(a.stanceScore, isNull, reason: 'out of range');
      expect(a.formScore, isNull);
      expect(a.tempoScore, 7, reason: 'rounded');
      expect(a.cameraView, CameraView.unclear);
      expect(a.confidence, Confidence.low);
      expect(a.repsCompleted, isNull);
      expect(a.stance, isEmpty);
      expect(a.cues, isEmpty);
      expect(a.goodPoints, ['real']);
    });

    test('a cue with no issue text is dropped; a bad severity becomes medium', () {
      final a = FormAnalysis.fromJson(_json(over: {
        'cues': [
          {'severity': 'high'},
          {'severity': 'catastrophic', 'issue': 'Knees cave'},
          'junk',
        ]
      }));
      expect(a.cues, hasLength(1));
      expect(a.cues.single.severity, CueSeverity.medium);
    });

    test('exercise_matches_request is only false when explicitly false', () {
      expect(FormAnalysis.fromJson(_json(over: {'exercise_matches_request': false})).exerciseMatchesRequest, isFalse);
      expect(FormAnalysis.fromJson(_json(over: {'exercise_matches_request': null})).exerciseMatchesRequest, isTrue);
    });

    test('round-trips through toJson', () {
      final a = FormAnalysis.fromJson(_json());
      final b = FormAnalysis.fromJson(a.toJson());
      expect(b.toJson(), a.toJson());
    });
  });

  group('bands', () {
    String? band(int? s) => FormAnalysis(overallScore: s).band;
    test('follow the plan: 9-10, 7-8, 5-6, below 5', () {
      expect(band(10), 'Excellent');
      expect(band(9), 'Excellent');
      expect(band(8), 'Good');
      expect(band(7), 'Good');
      expect(band(6), 'Needs work');
      expect(band(5), 'Needs work');
      expect(band(4), 'Worth correcting');
      expect(band(1), 'Worth correcting');
      expect(band(null), isNull);
    });
  });

  group('ExerciseVideo', () {
    ExerciseVideo video() => ExerciseVideo(
          id: 'a1',
          recordedAt: DateTime(2026, 11, 2, 9, 30),
          durationMs: 42500,
          sizeBytes: 9000000,
          exerciseName: 'Pull-Ups',
          exerciseKey: 'pullup',
          muscles: const ['upper-back', 'biceps'],
          workoutDate: DateTime(2026, 11, 2),
          dayLabel: 'Tuesday',
          filePath: 'exercise_videos/a1.mp4',
          thumbnailPath: 'exercise_videos/a1.jpg',
        );

    test('round-trips through a map', () {
      final v = ExerciseVideo.tryFromMap(video().toMap())!;
      expect(v.id, 'a1');
      expect(v.duration, const Duration(milliseconds: 42500));
      expect(v.muscles, ['upper-back', 'biceps']);
      expect(v.dayLabel, 'Tuesday');
      expect(v.isAnalysed, isFalse);
    });

    test('keeps its analysis, and when and with what it was made', () {
      final at = DateTime(2026, 11, 3);
      final v = ExerciseVideo.tryFromMap(
          video().withAnalysis(const FormAnalysis(overallScore: 8), at: at, model: 'm').toMap())!;
      expect(v.isAnalysed, isTrue);
      expect(v.analysis!.overallScore, 8);
      expect(v.analysedAt, at);
      expect(v.analysisModel, 'm');
    });

    test('a damaged record is skipped rather than thrown', () {
      expect(ExerciseVideo.tryFromMap({}), isNull);
      expect(ExerciseVideo.tryFromMap({'id': 'x', 'filePath': 'f'}), isNull, reason: 'no date');
      expect(ExerciseVideo.tryFromMap({'id': '', 'filePath': 'f', 'recordedAt': '2026-01-01'}), isNull);
    });

    test('an old record without a key gets one from the name', () {
      final m = video().toMap()..remove('exerciseKey');
      expect(ExerciseVideo.tryFromMap(m)!.exerciseKey, 'pullup');
    });
  });
}
