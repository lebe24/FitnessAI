// Design-review entry point for the workout history screens. Not part of the
// app: it shows them with sample sessions and nothing behind them.
//
//   flutter run -t lib/workout_history_preview.dart -d <device>
//
// On web, open a screen with
// ?screen=history|detail|nofeedback|empty|failed|lb|chips|share|sharepost
import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/session_share.dart';
import 'package:fitness/ui/features/analytic/views/share/session_share_graphic.dart';
import 'package:fitness/ui/features/analytic/views/share/session_share_page.dart';
import 'package:fitness/ui/features/analytic/history_samples.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/analytic/views/session_detail_page.dart';
import 'package:fitness/ui/features/analytic/views/workout_history_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    final screen = Uri.base.queryParameters['screen'] ?? 'history';
    final imperial = screen == 'lb';

    Future<List<WorkoutSessionModel>> loader() async => switch (screen) {
          'empty' => <WorkoutSessionModel>[],
          'failed' => throw Exception('offline'),
          'chips' => [
              for (final s in HistorySamples.all)
                HistorySamples.session(
                  DateTime(s.sessionDate.year - (s.sessionDate.month < 9 ? 1 : 0), s.sessionDate.month, s.sessionDate.day),
                  s.dayLabel,
                  minutes: s.durationMins ?? 0,
                  exercises: 6,
                  totalKg: 7000,
                ),
            ],
          _ => HistorySamples.all,
        };

    WorkoutSessionModel day(int d, int month, List<(String, String)> logs) => WorkoutSessionModel(
          sessionDate: DateTime(2025, month, d),
          dayLabel: 'Tuesday',
          durationMins: 160,
          workoutLogs: [
            for (final (name, sets) in logs) {'name': name, 'notes': sets}
          ],
        );
    final big = day(25, 11, [
      ('Barbell Squat', 'set 1: 20 reps @ 50kg | set 2: 7 reps @ 100kg | set 3: 5 reps @ 100kg | set 4: 5 reps @ 100kg'),
      ('Smith Machine Reverse Lunge', 'set 1: 12 reps @ 60kg | set 2: 8 reps @ 90kg | set 3: 10 reps @ 90kg'),
      ('Hanging Leg Raises', 'set 1: 8 reps @ 0kg | set 2: 10 reps @ 0kg | set 3: 10 reps @ 0kg'),
      ('Standing Calf Raises', 'set 1: 15 reps @ 150kg | set 2: 18 reps @ 150kg | set 3: 15 reps @ 150kg'),
      ('Smith machine RDL', 'set 1: 12 reps @ 90kg | set 2: 8 reps @ 100kg | set 3: 10 reps @ 100kg'),
      ('Leg Extension', 'set 1: 12 reps @ 80kg | set 2: 12 reps @ 95kg'),
      ('Lying Leg Curl', 'set 1: 12 reps @ 55kg | set 2: 10 reps @ 60kg'),
    ]);
    final earlier = day(18, 11, [
      ('Barbell Squat', 'set 1: 6 reps @ 95kg'),
      ('Smith machine RDL', 'set 1: 10 reps @ 90kg'),
    ]);
    SessionSharePage sharing(ShareFormat f) => SessionSharePage(
          share: SessionShare.of(big, history: [earlier]),
          imperial: false,
          initialFormat: f,
        );

    final Widget home = switch (screen) {
      'share' => sharing(ShareFormat.story),
      'sharepost' => sharing(ShareFormat.post),
      'detail' => SessionDetailPage(session: HistorySamples.all.first, imperial: false),
      'nofeedback' => SessionDetailPage(session: HistorySamples.all[1], imperial: false),
      _ => WorkoutHistoryPage(loader: loader, imperial: imperial),
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: kBodyBg),
      builder: (context, child) => ColoredBox(
        color: kBodyBg,
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 390), child: child)),
      ),
      home: home,
    );
  }
}
