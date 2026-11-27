import 'dart:io';

import 'package:fitness/data/services/video/form_analysis_usage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late DateTime clock;
  late FormAnalysisUsage usage;

  setUp(() {
    Hive.init(Directory.systemTemp.createTempSync('usage_hive').path);
    clock = DateTime.utc(2026, 11, 2, 12);
    usage = FormAnalysisUsage(now: () => clock);
  });
  tearDown(() async => Hive.close());

  test('starts at zero with the whole allowance left', () async {
    expect(await usage.usedThisMonth(), 0);
    expect(await usage.remaining(), FormAnalysisUsage.monthlyCap);
  });

  test('counts each recorded analysis', () async {
    expect(await usage.record(), 1);
    expect(await usage.record(), 2);
    expect(await usage.usedThisMonth(), 2);
    expect(await usage.remaining(), FormAnalysisUsage.monthlyCap - 2);
  });

  test('a new month starts again from zero', () async {
    await usage.record();
    await usage.record();
    clock = DateTime.utc(2026, 12, 1, 0, 5);
    expect(await usage.usedThisMonth(), 0);
    expect(await usage.record(), 1);
  });

  test('the last moment of a month still belongs to it', () async {
    clock = DateTime.utc(2026, 11, 30, 23, 59);
    await usage.record();
    clock = DateTime.utc(2026, 11, 30, 23, 59, 59);
    expect(await usage.usedThisMonth(), 1);
    clock = DateTime.utc(2026, 12, 1);
    expect(await usage.usedThisMonth(), 0);
  });

  test('old months are dropped, so the stored list stays small', () async {
    await usage.record();
    clock = DateTime.utc(2026, 12, 3);
    await usage.record();
    final raw = (await Hive.openBox('app_settings')).get('form_analysis_runs') as List;
    expect(raw, hasLength(1));
  });

  test('remaining never goes below zero', () async {
    for (var i = 0; i < FormAnalysisUsage.monthlyCap + 3; i++) {
      await usage.record();
    }
    expect(await usage.remaining(), 0);
  });

  test('survives being read by a fresh instance (an app restart)', () async {
    await usage.record();
    expect(await FormAnalysisUsage(now: () => clock).usedThisMonth(), 1);
  });

  test('a damaged stored value is ignored, not fatal', () async {
    final box = await Hive.openBox('app_settings');
    await box.put('form_analysis_runs', ['not a date', 5, null, '2026-11-02T10:00:00Z']);
    expect(await usage.usedThisMonth(), 1);
    await box.put('form_analysis_runs', 'garbage');
    expect(await usage.usedThisMonth(), 0);
  });
}
