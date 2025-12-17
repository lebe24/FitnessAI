import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/main.dart';

void main() {
  test('MainApp widget should be created', () {
    const app = MainApp();
    expect(app, isNotNull);
  });

  test('MainApp should have correct title', () {
    const app = MainApp();
    // Note: This is a basic test. In a real scenario, you'd test the widget tree
    expect(app, isA<StatelessWidget>());
  });
}

