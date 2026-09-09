/// Budget-cycle boundary resolution.
///
/// All dates here are LOCAL CALENDAR DATES (year/month/day), not UTC instants.
/// Budget-cycle limits are tied to the user's local day. Instant windows are
/// derived only at query time.
library;

/// A local calendar date.
class CalendarDate implements Comparable<CalendarDate> {
  const CalendarDate(this.year, this.month, this.day)
      : assert(year >= 1),
        assert(month >= 1 && month <= 12),
        assert(day >= 1 && day <= 31);

  final int year;
  final int month;
  final int day;

  static CalendarDate fromDateTime(DateTime local) =>
      CalendarDate(local.year, local.month, local.day);

  /// Parses 'yyyy-MM-dd'.
  static CalendarDate? tryParse(String iso) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (m == null) return null;
    final y = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    if (mo < 1 || mo > 12 || d < 1 || d > daysInMonth(y, mo)) return null;
    return CalendarDate(y, mo, d);
  }

  String get iso =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  static int daysInMonth(int year, int month) {
    const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && _isLeap(year)) return 29;
    return lengths[month - 1];
  }

  static bool _isLeap(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  CalendarDate addMonths(int months) {
    var y = year;
    var m = month + months;
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    return CalendarDate(y, m, day.clamp(1, daysInMonth(y, m)));
  }

  CalendarDate addDays(int days) {
    var d = DateTime(year, month, day).add(Duration(days: days));
    return CalendarDate(d.year, d.month, d.day);
  }

  /// Midnight in the local timezone for this calendar date.
  DateTime toLocalDateTime() => DateTime(year, month, day);

  /// Last instant (23:59:59.999) of this date in the local timezone.
  DateTime toLocalEndOfDay() => DateTime(year, month, day, 23, 59, 59, 999);

  /// Whole days from this date to [other] (positive when other is later).
  int daysUntil(CalendarDate other) {
    final a = DateTime(year, month, day);
    final b = DateTime(other.year, other.month, other.day);
    return b.difference(a).inDays;
  }

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) return year - other.year;
    if (month != other.month) return month - other.month;
    return day - other.day;
  }

  bool isBefore(CalendarDate other) => compareTo(other) < 0;
  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso;
}

/// A resolved budget-cycle window: inclusive [start] and [end] calendar dates.
class CycleWindow {
  const CycleWindow({required this.start, required this.end});

  final CalendarDate start;
  final CalendarDate end;

  bool containsDate(CalendarDate date) =>
      !date.isBefore(start) && !date.isAfter(end);

  int get totalDays => start.daysUntil(end) + 1;
}

/// Resolves which cycle contains a given date, given the configured start day.
///
/// The start day is the user's intent (1–31). When a month has fewer days,
/// the cycle start clamps to the last day of that month; the stored start day
/// keeps the user's intent.
class CycleResolver {
  /// Effective start day of [month]/[year] for a configured [startDay].
  static int effectiveStartDay(int startDay, int year, int month) =>
      startDay.clamp(1, CalendarDate.daysInMonth(year, month));

  /// The cycle window containing [today].
  static CycleWindow cycleContaining(int startDay, CalendarDate today) {
    final effThisMonth =
        effectiveStartDay(startDay, today.year, today.month);
    if (today.day >= effThisMonth) {
      return _windowFrom(startDay, CalendarDate(today.year, today.month, effThisMonth));
    }
    final prev = today.addMonths(-1);
    final effPrev = effectiveStartDay(startDay, prev.year, prev.month);
    return _windowFrom(startDay, CalendarDate(prev.year, prev.month, effPrev));
  }

  /// The cycle window for a cycle that starts exactly on [startDate].
  static CycleWindow _windowFrom(int startDay, CalendarDate startDate) {
    final nextMonth = startDate.addMonths(1);
    final effNext = effectiveStartDay(startDay, nextMonth.year, nextMonth.month);
    final nextStart = CalendarDate(nextMonth.year, nextMonth.month, effNext);
    return CycleWindow(start: startDate, end: nextStart.addDays(-1));
  }

  /// Builds the first cycle window when the budget is activated on
  /// [activationDate] (retroactive by default) or, when [startFromToday] is
  /// set, a partial cycle from today until the current period's natural end.
  static CycleWindow firstCycleWindow(
    int startDay,
    CalendarDate activationDate, {
    bool startFromToday = false,
  }) {
    final containing = cycleContaining(startDay, activationDate);
    if (startFromToday && activationDate.isAfter(containing.start)) {
      return CycleWindow(start: activationDate, end: containing.end);
    }
    return containing;
  }

  /// The next cycle window immediately following [endedWindow], using the
  /// configured [startDay].
  static CycleWindow nextWindowAfter(
    int startDay,
    CycleWindow endedWindow,
  ) {
    final nextMonth = endedWindow.start.addMonths(1);
    final effNext =
        effectiveStartDay(startDay, nextMonth.year, nextMonth.month);
    return _windowFrom(
        startDay, CalendarDate(nextMonth.year, nextMonth.month, effNext));
  }
}
