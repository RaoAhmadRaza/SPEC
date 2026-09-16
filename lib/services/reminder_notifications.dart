import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/reminder_schedule.dart';
import 'package:timezone/timezone.dart' as tz;

/// Reminders land at 09:00 local on the due day: early enough to act on,
/// late enough not to be the first thing on the lock screen.
const kReminderHour = 9;

/// iOS holds at most 64 pending local notifications and silently drops the
/// rest. Keeping the soonest is safe because every change reconciles again,
/// so a later one is scheduled as the earlier ones fire or move.
const kMaxScheduledReminders = 64;

const _channelId = 'reminders';
const _channelName = 'Reminders';

/// One notification the app wants pending. Its id is the object's id, so an
/// object can never hold two.
@immutable
class ReminderRequest {
  const ReminderRequest({
    required this.id,
    required this.body,
    required this.fireAt,
  });

  final int id;
  final String body;

  /// Local wall-clock time.
  final DateTime fireAt;

  @override
  bool operator ==(Object other) =>
      other is ReminderRequest &&
      other.id == id &&
      other.body == body &&
      other.fireAt == fireAt;

  @override
  int get hashCode => Object.hash(id, body, fireAt);

  @override
  String toString() => 'ReminderRequest($id, $fireAt, $body)';
}

/// The four calls reconciling needs, so tests can hold notifications in a
/// map instead of a platform channel.
abstract interface class ReminderScheduler {
  Future<Set<int>> pendingIds();
  Future<void> requestPermission();
  Future<void> schedule(ReminderRequest request);
  Future<void> cancel(int id);
}

/// The notifications [objects] call for at [now], soonest first.
///
/// A reminder whose moment has passed gets none: an overdue object already
/// says DUE on its card, and a notification for yesterday would fire at once.
List<ReminderRequest> plannedReminders(
  Iterable<SpecObject> objects,
  DateTime now,
) {
  final planned = <ReminderRequest>[
    for (final object in objects)
      if (nextDueDate(
            remindEveryMonths: object.remindEveryMonths,
            replacedOn: object.replacedOn,
            createdAt: object.createdAt,
          )
          case final DateTime due)
        ReminderRequest(
          id: object.id,
          body: 'Time to replace: ${object.name} · ${object.specValue}',
          fireAt: DateTime(due.year, due.month, due.day, kReminderHour),
        ),
  ]..retainWhere((request) => request.fireAt.isAfter(now));
  planned.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return planned.take(kMaxScheduledReminders).toList();
}

/// Makes the pending notifications exactly [wanted]: stale ones cancelled,
/// the rest (re)scheduled. Permission is asked only once something actually
/// needs it, never at launch.
///
/// ponytail: reschedules every wanted reminder on each call rather than
/// diffing fire dates; at most 64 cheap platform calls per objects change.
Future<void> reconcileReminders(
  ReminderScheduler scheduler,
  List<ReminderRequest> wanted,
) async {
  final keep = {for (final request in wanted) request.id};
  for (final id in (await scheduler.pendingIds()).difference(keep)) {
    await scheduler.cancel(id);
  }
  if (wanted.isEmpty) return;
  await scheduler.requestPermission();
  for (final request in wanted) {
    await scheduler.schedule(request);
  }
}

/// [ReminderScheduler] on flutter_local_notifications.
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;
  Future<void>? _permission;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(_channelId, _channelName),
    iOS: DarwinNotificationDetails(),
  );

  /// Initialised on first use, with every permission flag off, so starting
  /// the plugin never shows a prompt. Tapping a notification just opens the
  /// app, which needs no callback.
  Future<void> _init() => _ready ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  @override
  Future<Set<int>> pendingIds() async {
    await _init();
    return {
      for (final request in await _plugin.pendingNotificationRequests())
        request.id,
    };
  }

  /// Once per launch. The OS itself prompts only the first time and answers
  /// from memory after that.
  @override
  Future<void> requestPermission() async {
    await _init();
    return _permission ??= _askPermission();
  }

  Future<void> _askPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> schedule(ReminderRequest request) async {
    await _init();
    await _plugin.zonedSchedule(
      id: request.id,
      body: request.body,
      // The local wall-clock time, pinned as a UTC instant. Dart resolves
      // DST for that date, and it needs no timezone database or native
      // timezone lookup; the next launch's reconcile re-pins it if the user
      // has since changed zone.
      scheduledDate: tz.TZDateTime.from(request.fireAt, tz.UTC),
      notificationDetails: _details,
      // Inexact needs no exact-alarm permission, and minutes do not matter.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _init();
    await _plugin.cancel(id: id);
  }
}
