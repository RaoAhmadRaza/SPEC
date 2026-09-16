import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/services/reminder_notifications.dart';

import '../support/reminders.dart';

/// 15 Sep 2026, mid-morning: past today's 09:00.
final _now = DateTime(2026, 9, 15, 10, 30);

SpecObject _object({
  int id = 1,
  String name = 'Bulb',
  String spec = 'B22',
  int? every,
  String? replacedOn,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime(2026, 1, 1);
  return SpecObject(
    id: id,
    name: name,
    type: 'product',
    specKind: 'model',
    specValue: spec,
    attributes: '[]',
    replacedOn: replacedOn,
    remindEveryMonths: every,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  group('plannedReminders', () {
    test('one notification at 09:00 on the due day', () {
      final planned = plannedReminders([
        _object(every: 6, replacedOn: '2026-08-14'),
      ], _now);

      expect(planned, [
        ReminderRequest(
          id: 1,
          body: 'Time to replace: Bulb · B22',
          fireAt: DateTime(2027, 2, 14, 9),
        ),
      ]);
    });

    test('nothing for an object with no reminder', () {
      expect(plannedReminders([_object()], _now), isEmpty);
    });

    test('nothing once the moment has passed: the card covers overdue', () {
      final planned = plannedReminders([
        _object(id: 1, every: 1, replacedOn: '2026-01-01'),
        // Due today, but 09:00 has already gone.
        _object(id: 2, every: 1, replacedOn: '2026-08-15'),
      ], _now);

      expect(planned, isEmpty);
    });

    test('due today before 09:00 still fires today', () {
      final planned = plannedReminders([
        _object(every: 1, replacedOn: '2026-08-15'),
      ], DateTime(2026, 9, 15, 8));

      expect(planned.single.fireAt, DateTime(2026, 9, 15, 9));
    });

    test('keeps only the soonest the OS will hold', () {
      final objects = [
        for (var i = 0; i < kMaxScheduledReminders + 5; i++)
          // Later ids fall due sooner.
          _object(
            id: i,
            every: 1,
            createdAt: DateTime(2026, 9, 1).subtract(Duration(days: i)),
          ),
      ];

      final planned = plannedReminders(objects, DateTime(2026, 6, 1));

      expect(planned, hasLength(kMaxScheduledReminders));
      expect(planned.map((r) => r.id), isNot(contains(0)));
      expect(planned.map((r) => r.id), contains(kMaxScheduledReminders + 4));
    });
  });

  group('reconcileReminders', () {
    late FakeReminderScheduler scheduler;

    setUp(() => scheduler = FakeReminderScheduler());

    ReminderRequest request(int id, DateTime fireAt) =>
        ReminderRequest(id: id, body: 'Time to replace: $id', fireAt: fireAt);

    test('schedules what is wanted and asks permission for it', () async {
      await reconcileReminders(scheduler, [request(1, DateTime(2027))]);

      expect(scheduler.pending.keys, [1]);
      expect(scheduler.permissionRequests, 1);
    });

    test('never asks permission when there is nothing to schedule', () async {
      await reconcileReminders(scheduler, const []);

      expect(scheduler.permissionRequests, 0);
    });

    test('moves a notification whose date changed', () async {
      await reconcileReminders(scheduler, [request(1, DateTime(2027))]);
      await reconcileReminders(scheduler, [request(1, DateTime(2028))]);

      expect(scheduler.pending[1]!.fireAt, DateTime(2028));
    });

    test('cancels what is no longer wanted', () async {
      await reconcileReminders(scheduler, [
        request(1, DateTime(2027)),
        request(2, DateTime(2027)),
      ]);
      await reconcileReminders(scheduler, [request(2, DateTime(2027))]);

      expect(scheduler.pending.keys, [2]);

      await reconcileReminders(scheduler, const []);

      expect(scheduler.pending, isEmpty);
    });
  });
}
