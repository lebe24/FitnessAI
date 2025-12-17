// This file contains widget tests for the Fitness AI application.
// For unit tests, see the test/ directory structure.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/main.dart';

void main() {
  testWidgets('MainApp widget should render', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MainApp());

    // Verify that the app renders without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
