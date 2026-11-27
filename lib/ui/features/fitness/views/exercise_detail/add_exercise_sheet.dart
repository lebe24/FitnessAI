import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:flutter/material.dart';

/// What happened when exercises were added.
enum ExerciseAddOutcome {
  /// In today's workout.
  today,

  /// In today's workout and the saved plan.
  todayAndPlan,

  /// In today's workout, but the plan could not be saved.
  planFailed,
}

/// Asks where an added exercise should go. Returns true to also add it to the
/// saved plan, false for today only, null if dismissed.
Future<bool?> showAddExerciseChoice(
  BuildContext context, {
  required List<String> names,
  Future<bool>? canAddToPlan,
}) {
  return showBodySheet<bool>(
    context,
    (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Text(names.length == 1 ? 'Add ${names.single}?' : 'Add ${names.length} exercises?', style: bodyHeading(17)),
          if (names.length > 1) ...[
            const SizedBox(height: 6),
            Text(names.join(' · '), style: bodyText(12.5, color: kBodyMuted, height: 1.45)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: BodyButton(label: 'Just today', onPressed: () => Navigator.of(sheet).pop(false)),
          ),
          const SizedBox(height: 8),
          FutureBuilder<bool>(
            future: canAddToPlan ?? Future.value(false),
            builder: (context, snap) {
              final can = snap.data ?? false;
              final checking = snap.connectionState != ConnectionState.done;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: BodyButton(
                      label: 'Also add to my plan',
                      filled: false,
                      busy: checking,
                      onPressed: can ? () => Navigator.of(sheet).pop(true) : null,
                    ),
                  ),
                  if (!checking && !can)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('This workout is not a day in your saved plan.',
                          style: bodyText(11.5, color: kBodyMuted)),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
