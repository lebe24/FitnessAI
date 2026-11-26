/// A calendar month that has at least one logged session.
class HistoryMonth implements Comparable<HistoryMonth> {
  final int year;
  final int month;
  const HistoryMonth(this.year, this.month);

  factory HistoryMonth.of(DateTime d) => HistoryMonth(d.year, d.month);

  bool contains(DateTime d) => d.year == year && d.month == month;

  static const _names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// `Nov`, or `Nov '25` when [withYear].
  String label({bool withYear = false}) =>
      withYear ? "${_names[month - 1]} '${(year % 100).toString().padLeft(2, '0')}" : _names[month - 1];

  @override
  int compareTo(HistoryMonth other) => (year * 12 + month) - (other.year * 12 + other.month);

  @override
  bool operator ==(Object other) => other is HistoryMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  /// The months present in [dates], oldest first.
  static List<HistoryMonth> distinct(Iterable<DateTime> dates) {
    final set = {for (final d in dates) HistoryMonth.of(d)};
    return set.toList()..sort();
  }

  /// Whether the list needs years on its labels: more than one year, or the
  /// same month name would appear twice.
  static bool spansYears(List<HistoryMonth> months) => months.map((m) => m.year).toSet().length > 1;
}
