import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/reminder_schedule.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/services/reminder_notifications.dart';

part 'reminders.g.dart';

/// Overridden with a fake in tests, which have no platform channel.
@Riverpod(keepAlive: true)
ReminderScheduler reminderScheduler(Ref ref) => LocalReminderScheduler();

/// Keeps the pending notifications in step with the objects table.
///
/// Watches the table itself rather than hooking each write, so add, edit,
/// REPLACED, delete, restore and delete-everything are all covered by one
/// listener. The table, not `ObjectRepository.watchAll`, because summaries
/// do not carry the reminder columns.
///
/// Read once from the app root and kept alive. Nothing awaits it: a failure
/// here costs a notification, never the launch.
@Riverpod(keepAlive: true)
Future<void> reminderSync(Ref ref) async {
  final database = await ref.watch(specDatabaseProvider.future);
  final scheduler = ref.watch(reminderSchedulerProvider);

  // Chained, so two quick writes never interleave their cancels and schedules.
  var queue = Future<void>.value();
  final subscription = database
      .select(database.objects)
      .watch()
      .listen(
        (rows) => queue = queue.then((_) => _reconcile(scheduler, rows)),
        onError: _report,
      );
  ref.onDispose(subscription.cancel);
}

/// Ids of the objects whose reminder has fallen due by [now]: what Home
/// marks DUE.
Future<Set<int>> dueObjectIds(SpecDatabase database, DateTime now) async {
  final query = database.select(database.objects)
    ..where((o) => o.remindEveryMonths.isNotNull());
  return {
    for (final o in await query.get())
      if (nextDueDate(
            remindEveryMonths: o.remindEveryMonths,
            replacedOn: o.replacedOn,
            createdAt: o.createdAt,
          )
          case final DateTime due when isOverdue(due, now))
        o.id,
  };
}

Future<void> _reconcile(
  ReminderScheduler scheduler,
  List<SpecObject> rows,
) async {
  try {
    await reconcileReminders(scheduler, plannedReminders(rows, DateTime.now()));
  } on Object catch (error, stack) {
    _report(error, stack);
  }
}

void _report(Object error, StackTrace stack) => FlutterError.reportError(
  FlutterErrorDetails(
    exception: error,
    stack: stack,
    library: 'reminders',
    context: ErrorDescription('while scheduling reminder notifications'),
  ),
);
