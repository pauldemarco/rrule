import 'package:basics/basics.dart';
import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';

import '../frequency.dart';
import '../recurrence_rule.dart';
import '../utils.dart';

@immutable
class DateSet {
  const DateSet._({
    @required this.isIncluded,
    @required this.start,
    @required this.end,
    @required this.firstDayOfYear,
  })  : assert(isIncluded != null),
        assert(start != null),
        assert(start >= 0),
        assert(end != null),
        assert(start <= end),
        assert(firstDayOfYear != null);

  factory DateSet.create({
    @required LocalDate base,
    bool addExtraWeek = false,
    int start = 0,
    int end,
  }) {
    assert(base != null);
    assert(addExtraWeek != null);
    assert(start != null);

    var length = base.calendar.getDaysInYear(base.year);
    if (addExtraWeek) {
      length += TimeConstants.daysPerWeek;
    }
    end ??= length;

    return DateSet._(
      isIncluded: List.generate(length, (i) => start <= i && i < end),
      start: start,
      end: end,
      firstDayOfYear: base.copyWith(month: 1, day: 1),
    );
  }

  /// Each entry corresponds to whether the respective date of the year is
  /// potentially included in the result set.
  final List<bool> isIncluded;

  /// Inclusive index of the first `true` value.
  final int start;

  /// Exclusive index of the last `true` value.
  final int end;

  final LocalDate firstDayOfYear;

  LocalDate operator [](int index) {
    if (!isIncluded[index]) {
      return null;
    }

    return firstDayOfYear + Period(days: index);
  }

  Iterable<LocalDate> get includedDates =>
      start.to(end).map((i) => this[i]).where((d) => d != null);
}

DateSet makeDateSet(RecurrenceRule rrule, LocalDate base) {
  if (rrule.frequency == Frequency.yearly) {
    return _buildYearlyDateSet(base);
  } else if (rrule.frequency == Frequency.monthly) {
    return _buildMonthlyDateSet(base);
  } else if (rrule.frequency == Frequency.weekly) {
    return _buildWeeklyDateSet(base, rrule.actualWeekStart);
  } else {
    assert(rrule.frequency >= Frequency.daily);
    return _buildDailyDateSet(base);
  }
}

DateSet _buildYearlyDateSet(LocalDate base) => DateSet.create(base: base);

DateSet _buildMonthlyDateSet(LocalDate base) {
  return DateSet.create(
    base: base,
    start: base.adjust(DateAdjusters.startOfMonth).dayOfYear - 1,
    end: base.adjust(DateAdjusters.endOfMonth).dayOfYear,
  );
}

DateSet _buildWeeklyDateSet(LocalDate base, DayOfWeek weekStart) {
  // We need to handle cross-year weeks here.
  var i = base.dayOfYear - 1;
  final start = i;
  var current = base;
  for (final _ in 0.to(TimeConstants.daysPerWeek)) {
    i++;
    current += Period(days: 1);
    if (current.dayOfWeek == weekStart) {
      break;
    }
  }
  return DateSet.create(
    base: base,
    addExtraWeek: true,
    start: start,
    end: i,
  );
}

DateSet _buildDailyDateSet(LocalDate base) {
  final dayOfYear = base.dayOfYear - 1;
  return DateSet.create(base: base, start: dayOfYear, end: dayOfYear + 1);
}
