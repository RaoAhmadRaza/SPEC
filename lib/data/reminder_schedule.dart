import 'dart:math' as math;

/// When a reminder falls due. Derived on read from `replaced_on`,
/// `created_at` and `remind_every_months`, which is why there is no reminders
/// table to keep in step with the objects.
///
/// Days, not instants: a filter is due on the 15th, not at 14:32 on it.

/// [day] plus [months] calendar months, at midnight.
///
/// Clamped to the target month's last day rather than rolled over, so 31 Jan
/// plus a month is the end of February — not 3 March, which is what
/// `DateTime` would make of it.
DateTime addMonths(DateTime day, int months) {
  // Day 1 cannot overflow, so this normalises the month and year first.
  final target = DateTime(day.year, day.month + months);
  // Day 0 of the following month is the last day of this one.
  final lastDay = DateTime(target.year, target.month + 1, 0).day;
  return DateTime(target.year, target.month, math.min(day.day, lastDay));
}

/// The next due day, or null when the object has no reminder.
///
/// Counts from the last replacement, or from the day the object was added if
/// it has never been replaced. A `replaced_on` this build cannot read counts
/// as never replaced rather than hiding the reminder.
///
/// [createdAt] is nullable only for presentation models built without one;
/// every stored row has it.
DateTime? nextDueDate({
  required int? remindEveryMonths,
  required String? replacedOn,
  required DateTime? createdAt,
}) {
  final every = remindEveryMonths;
  if (every == null || every <= 0) return null;
  final replaced = replacedOn == null ? null : DateTime.tryParse(replacedOn);
  final from = replaced ?? createdAt;
  return from == null ? null : addMonths(from, every);
}

/// True from the first minute of the due day. On the day itself the card
/// already says DUE: that is the day to do it.
bool isOverdue(DateTime due, DateTime now) =>
    !DateTime(now.year, now.month, now.day).isBefore(due);
