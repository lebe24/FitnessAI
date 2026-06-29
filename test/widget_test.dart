// Smoke test: verify the top-level MainApp widget can be constructed.
// Full unit tests live in test/unit/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/main.dart';

void main() {
  test('MainApp can be instantiated', () {
    const app = MainApp();
    expect(app, isA<StatelessWidget>());
  });
}
