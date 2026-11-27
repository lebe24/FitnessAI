import 'package:fitness/ui/features/progression/progression_samples.dart';
import 'package:fitness/ui/features/progression/views/progression_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> open(WidgetTester tester, {
    Future<bool> Function(Set<int>)? onApply,
    Future<bool> Function()? onUndo,
    Future<void> Function()? onDismiss,
  }) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: ProgressionReviewPage(
        proposal: ProgressionSamples.ready,
        onApply: onApply,
        onUndo: onUndo,
        onDismiss: onDismiss,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('applies every change by default', (tester) async {
    Set<int>? got;
    await open(tester, onApply: (skipped) async {
      got = skipped;
      return true;
    });
    expect(find.text('Apply all 8 changes'), findsOneWidget);
    await tester.tap(find.text('Apply all 8 changes'));
    await tester.pumpAndSettle();
    expect(got, isEmpty);
    expect(find.text('Plan updated to v6'), findsOneWidget);
  });

  testWidgets('a change that is unticked is reported as skipped', (tester) async {
    Set<int>? got;
    await open(tester, onApply: (skipped) async {
      got = skipped;
      return true;
    });
    await tester.tap(find.text('Lateral Raise'));
    await tester.pumpAndSettle();
    expect(find.text('Apply 7 of 8 changes'), findsOneWidget);

    await tester.tap(find.text('Apply 7 of 8 changes'));
    await tester.pumpAndSettle();
    final lateral = ProgressionSamples.ready.changes.indexWhere((c) => c.exercise == 'Lateral Raise');
    expect(got, {lateral});
  });

  testWidgets('a hold cannot be ticked', (tester) async {
    await open(tester);
    await tester.tap(find.text('Overhead Press'));
    await tester.pumpAndSettle();
    expect(find.text('Apply all 8 changes'), findsOneWidget);
  });

  testWidgets('stays on the review when saving fails', (tester) async {
    await open(tester, onApply: (_) async => false);
    await tester.tap(find.text('Apply all 8 changes'));
    await tester.pumpAndSettle();
    expect(find.text('Plan updated to v6'), findsNothing);
    expect(find.text('Could not update your plan. Try again.'), findsOneWidget);
  });

  testWidgets('"not this time" is reported', (tester) async {
    var dismissed = false;
    await open(tester, onDismiss: () async => dismissed = true);
    await tester.tap(find.text('Not this time'));
    await tester.pumpAndSettle();
    expect(dismissed, isTrue);
  });
}
