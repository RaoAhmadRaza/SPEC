import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/reminder_schedule.dart';

void main() {
  group('addMonths', () {
    test('keeps the day when the target month has it', () {
      expect(addMonths(DateTime(2026, 8, 14), 6), DateTime(2027, 2, 14));
    });

    test('clamps to the last day of a shorter month', () {
      expect(addMonths(DateTime(2027, 1, 31), 1), DateTime(2027, 2, 28));
      expect(addMonths(DateTime(2026, 3, 31), 1), DateTime(2026, 4, 30));
      expect(addMonths(DateTime(2026, 8, 31), 1), DateTime(2026, 9, 30));
    });

    test('lands on 29 Feb in a leap year', () {
      expect(addMonths(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
      expect(addMonths(DateTime(2028, 2, 29), 12), DateTime(2029, 2, 28));
      expect(addMonths(DateTime(2024, 2, 29), 48), DateTime(2028, 2, 29));
    });

    test('rolls the year over', () {
      expect(addMonths(DateTime(2026, 11, 30), 3), DateTime(2027, 2, 28));
      expect(addMonths(DateTime(2026, 12, 15), 25), DateTime(2029, 1, 15));
    });

    test('drops the time of day', () {
      expect(
        addMonths(DateTime(2026, 8, 14, 23, 59), 1),
        DateTime(2026, 9, 14),
      );
    });
  });

  group('nextDueDate', () {
    final created = DateTime(2026, 1, 10, 14, 32);

    test('counts from the replacement date when there is one', () {
      expect(
        nextDueDate(
          remindEveryMonths: 6,
          replacedOn: '2026-08-14',
          createdAt: created,
        ),
        DateTime(2027, 2, 14),
      );
    });

    test('counts from the day it was added when never replaced', () {
      expect(
        nextDueDate(remindEveryMonths: 3, replacedOn: null, createdAt: created),
        DateTime(2026, 4, 10),
      );
    });

    test('falls back to the added day when the stored date is unreadable', () {
      expect(
        nextDueDate(
          remindEveryMonths: 1,
          replacedOn: 'garbage',
          createdAt: created,
        ),
        DateTime(2026, 2, 10),
      );
    });

    test('is null with nothing to count from', () {
      expect(
        nextDueDate(remindEveryMonths: 6, replacedOn: null, createdAt: null),
        isNull,
      );
    });

    test('is null with no interval, or a zero or negative one', () {
      for (final every in [null, 0, -2]) {
        expect(
          nextDueDate(
            remindEveryMonths: every,
            replacedOn: '2026-08-14',
            createdAt: created,
          ),
          isNull,
        );
      }
    });
  });

  group('isOverdue', () {
    final due = DateTime(2027, 3, 15);

    test('not before the day', () {
      expect(isOverdue(due, DateTime(2027, 3, 14, 23, 59)), isFalse);
    });

    test('from the first minute of the day onwards', () {
      expect(isOverdue(due, DateTime(2027, 3, 15)), isTrue);
      expect(isOverdue(due, DateTime(2027, 3, 15, 8)), isTrue);
      expect(isOverdue(due, DateTime(2028, 1, 1)), isTrue);
    });
  });
}
