import 'package:fitness/domain/models/exercise_history.dart';

/// A workout video saved on the device against one exercise.
///
/// The file and thumbnail live in the app's documents folder; [filePath] and
/// [thumbnailPath] are relative to it, so they survive the app being moved
/// (the documents folder's absolute path changes between iOS installs).
class ExerciseVideo {
  final String id;
  final DateTime recordedAt;
  final int durationMs;
  final int sizeBytes;

  final String exerciseName;

  /// [ExerciseHistory.keyFor] of the name, so "Pull-Ups" and "pull up" group.
  final String exerciseKey;

  /// Muscle slugs, resolved when the video was saved so later changes to the
  /// muscle logic don't move old videos between muscles.
  final List<String> muscles;

  final DateTime? workoutDate;
  final String? dayLabel;

  final String filePath;
  final String thumbnailPath;

  final FormAnalysis? analysis;
  final DateTime? analysedAt;
  final String? analysisModel;
  final String? note;

  const ExerciseVideo({
    required this.id,
    required this.recordedAt,
    required this.durationMs,
    required this.sizeBytes,
    required this.exerciseName,
    required this.exerciseKey,
    required this.muscles,
    required this.filePath,
    required this.thumbnailPath,
    this.workoutDate,
    this.dayLabel,
    this.analysis,
    this.analysedAt,
    this.analysisModel,
    this.note,
  });

  Duration get duration => Duration(milliseconds: durationMs);
  bool get isAnalysed => analysis != null;

  ExerciseVideo withAnalysis(
    FormAnalysis analysis, {
    required DateTime at,
    String? model,
  }) =>
      ExerciseVideo(
        id: id,
        recordedAt: recordedAt,
        durationMs: durationMs,
        sizeBytes: sizeBytes,
        exerciseName: exerciseName,
        exerciseKey: exerciseKey,
        muscles: muscles,
        filePath: filePath,
        thumbnailPath: thumbnailPath,
        workoutDate: workoutDate,
        dayLabel: dayLabel,
        analysis: analysis,
        analysedAt: at,
        analysisModel: model,
        note: note,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'recordedAt': recordedAt.toIso8601String(),
        'durationMs': durationMs,
        'sizeBytes': sizeBytes,
        'exerciseName': exerciseName,
        'exerciseKey': exerciseKey,
        'muscles': muscles,
        if (workoutDate != null) 'workoutDate': workoutDate!.toIso8601String(),
        if (dayLabel != null) 'dayLabel': dayLabel,
        'filePath': filePath,
        'thumbnailPath': thumbnailPath,
        if (analysis != null) 'analysis': analysis!.toJson(),
        if (analysedAt != null) 'analysedAt': analysedAt!.toIso8601String(),
        if (analysisModel != null) 'analysisModel': analysisModel,
        if (note != null) 'note': note,
      };

  /// Null for a record too damaged to use (no id, path or date), so one bad
  /// entry can't take the whole list down.
  static ExerciseVideo? tryFromMap(Map m) {
    final id = m['id'];
    final file = m['filePath'];
    final recorded = DateTime.tryParse('${m['recordedAt']}');
    if (id is! String || id.isEmpty || file is! String || recorded == null) {
      return null;
    }
    final name = m['exerciseName'] is String ? m['exerciseName'] as String : '';
    FormAnalysis? analysis;
    if (m['analysis'] is Map) {
      analysis = FormAnalysis.fromJson(Map<String, dynamic>.from(m['analysis'] as Map));
    }
    return ExerciseVideo(
      id: id,
      recordedAt: recorded,
      durationMs: (m['durationMs'] as num?)?.toInt() ?? 0,
      sizeBytes: (m['sizeBytes'] as num?)?.toInt() ?? 0,
      exerciseName: name,
      exerciseKey: m['exerciseKey'] is String
          ? m['exerciseKey'] as String
          : ExerciseHistory.keyFor(name),
      muscles: [
        if (m['muscles'] is List) ...(m['muscles'] as List).whereType<String>(),
      ],
      workoutDate: DateTime.tryParse('${m['workoutDate']}'),
      dayLabel: m['dayLabel'] as String?,
      filePath: file,
      thumbnailPath: m['thumbnailPath'] is String ? m['thumbnailPath'] as String : '',
      analysis: analysis,
      analysedAt: DateTime.tryParse('${m['analysedAt']}'),
      analysisModel: m['analysisModel'] as String?,
      note: m['note'] as String?,
    );
  }
}

enum CameraView { side, front, rear, angled, unclear }

enum Confidence { high, medium, low }

enum CueSeverity { high, medium, low }

/// The AI's rating of one clip. Any score can be null: the model says so when
/// the camera angle hides what that score needs, and the UI shows "can't judge"
/// rather than a number.
class FormAnalysis {
  final String exercise;
  final bool exerciseMatchesRequest;
  final CameraView cameraView;
  final Confidence confidence;

  /// 1–10. [overallScore] is computed by the backend from the three below.
  final int? overallScore;
  final int? stanceScore;
  final int? formScore;
  final int? tempoScore;

  final String summary;
  final int? repsCompleted;
  final int? repAttempts;
  final String repNotes;
  final List<String> stance;
  final List<String> form;
  final List<String> tempo;
  final List<FormCue> cues;
  final List<String> goodPoints;
  final List<String> limitations;

  const FormAnalysis({
    this.exercise = '',
    this.exerciseMatchesRequest = true,
    this.cameraView = CameraView.unclear,
    this.confidence = Confidence.low,
    this.overallScore,
    this.stanceScore,
    this.formScore,
    this.tempoScore,
    this.summary = '',
    this.repsCompleted,
    this.repAttempts,
    this.repNotes = '',
    this.stance = const [],
    this.form = const [],
    this.tempo = const [],
    this.cues = const [],
    this.goodPoints = const [],
    this.limitations = const [],
  });

  /// This result with one more thing it could not judge, and its confidence
  /// brought down to low. Used when the frames were a guess (no movement found).
  FormAnalysis withLimitation(String note) => FormAnalysis(
        exercise: exercise,
        exerciseMatchesRequest: exerciseMatchesRequest,
        cameraView: cameraView,
        confidence: Confidence.low,
        overallScore: overallScore,
        stanceScore: stanceScore,
        formScore: formScore,
        tempoScore: tempoScore,
        summary: summary,
        repsCompleted: repsCompleted,
        repAttempts: repAttempts,
        repNotes: repNotes,
        stance: stance,
        form: form,
        tempo: tempo,
        cues: cues,
        goodPoints: goodPoints,
        limitations: [...limitations, note],
      );

  /// More tries than clean reps: something didn't go up.
  bool get hadFailedAttempt =>
      repsCompleted != null && repAttempts != null && repAttempts! > repsCompleted!;

  /// The word for the overall score: 9–10 excellent, 7–8 good, 5–6 needs work,
  /// below 5 worth correcting. Null when there is no score.
  String? get band {
    final s = overallScore;
    if (s == null) return null;
    if (s >= 9) return 'Excellent';
    if (s >= 7) return 'Good';
    if (s >= 5) return 'Needs work';
    return 'Worth correcting';
  }

  /// Reads defensively: this is model output that has passed the backend's
  /// schema, but a stored result from an older version, or a field the app
  /// doesn't know, must degrade to "missing" and never throw.
  factory FormAnalysis.fromJson(Map<String, dynamic> json) {
    int? score(dynamic v) {
      if (v is! num) return null;
      final n = v.round();
      return n >= 1 && n <= 10 ? n : null;
    }

    int? count(dynamic v) => v is num && v >= 0 ? v.round() : null;
    String text(dynamic v) => v is String ? v : '';
    List<String> lines(dynamic v) => v is List
        ? v.whereType<String>().where((s) => s.trim().isNotEmpty).toList()
        : const [];
    T pick<T extends Enum>(List<T> values, dynamic v, T fallback) {
      for (final e in values) {
        if (e.name == v) return e;
      }
      return fallback;
    }

    final reps = json['reps'] is Map ? json['reps'] as Map : const {};
    return FormAnalysis(
      exercise: text(json['exercise']),
      exerciseMatchesRequest: json['exercise_matches_request'] != false,
      cameraView: pick(CameraView.values, json['camera_view'], CameraView.unclear),
      confidence: pick(Confidence.values, json['confidence'], Confidence.low),
      overallScore: score(json['overall_score']),
      stanceScore: score(json['stance_score']),
      formScore: score(json['form_score']),
      tempoScore: score(json['tempo_score']),
      summary: text(json['summary']),
      repsCompleted: count(reps['completed']),
      repAttempts: count(reps['attempts']),
      repNotes: text(reps['notes']),
      stance: lines(json['stance']),
      form: lines(json['form']),
      tempo: lines(json['tempo']),
      cues: [
        if (json['cues'] is List)
          for (final c in (json['cues'] as List).whereType<Map>())
            if (FormCue.tryFromJson(Map<String, dynamic>.from(c)) case final cue?) cue,
      ],
      goodPoints: lines(json['good_points']),
      limitations: lines(json['limitations']),
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise': exercise,
        'exercise_matches_request': exerciseMatchesRequest,
        'camera_view': cameraView.name,
        'confidence': confidence.name,
        'overall_score': overallScore,
        'stance_score': stanceScore,
        'form_score': formScore,
        'tempo_score': tempoScore,
        'summary': summary,
        'reps': {
          'completed': repsCompleted,
          'attempts': repAttempts,
          'notes': repNotes,
        },
        'stance': stance,
        'form': form,
        'tempo': tempo,
        'cues': [for (final c in cues) c.toJson()],
        'good_points': goodPoints,
        'limitations': limitations,
      };
}

class FormCue {
  final CueSeverity severity;
  final String issue;
  final String fix;

  const FormCue({required this.severity, required this.issue, this.fix = ''});

  /// Null when there is no issue text: a cue with nothing to say is dropped.
  static FormCue? tryFromJson(Map<String, dynamic> json) {
    final issue = json['issue'];
    if (issue is! String || issue.trim().isEmpty) return null;
    return FormCue(
      severity: CueSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => CueSeverity.medium,
      ),
      issue: issue.trim(),
      fix: json['fix'] is String ? (json['fix'] as String).trim() : '',
    );
  }

  Map<String, dynamic> toJson() =>
      {'severity': severity.name, 'issue': issue, 'fix': fix};
}
