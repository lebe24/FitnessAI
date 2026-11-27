import 'package:fitness/domain/models/history_months.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('distinct months come back oldest first', () {
    final months = HistoryMonth.distinct([
      DateTime(2025, 11, 20),
      DateTime(2025, 9, 2),
      DateTime(2025, 11, 3),
      DateTime(2024, 12, 30),
    ]);
    expect(months, [const HistoryMonth(2024, 12), const HistoryMonth(2025, 9), const HistoryMonth(2025, 11)]);
  });

  test('contains matches the month and year only', () {
    const nov = HistoryMonth(2025, 11);
    expect(nov.contains(DateTime(2025, 11, 1)), isTrue);
    expect(nov.contains(DateTime(2025, 11, 30, 23, 59)), isTrue);
    expect(nov.contains(DateTime(2024, 11, 20)), isFalse);
    expect(nov.contains(DateTime(2025, 12, 1)), isFalse);
  });

  test('labels, with the year when asked', () {
    expect(const HistoryMonth(2025, 11).label(), 'Nov');
    expect(const HistoryMonth(2025, 1).label(withYear: true), "Jan '25");
    expect(const HistoryMonth(2009, 5).label(withYear: true), "May '09");
  });

  test('years are shown only when the months span more than one', () {
    expect(HistoryMonth.spansYears(const [HistoryMonth(2025, 9), HistoryMonth(2025, 11)]), isFalse);
    expect(HistoryMonth.spansYears(const [HistoryMonth(2024, 11), HistoryMonth(2025, 11)]), isTrue);
    expect(HistoryMonth.spansYears(const []), isFalse);
  });
}
