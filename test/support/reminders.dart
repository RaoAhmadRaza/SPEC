import 'package:spec/services/reminder_notifications.dart';

/// Holds "scheduled" notifications in a map, the way the OS holds pending
/// ones: scheduling an id again replaces it.
class FakeReminderScheduler implements ReminderScheduler {
  final pending = <int, ReminderRequest>{};
  var permissionRequests = 0;

  @override
  Future<Set<int>> pendingIds() async => pending.keys.toSet();

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<void> schedule(ReminderRequest request) async =>
      pending[request.id] = request;

  @override
  Future<void> cancel(int id) async => pending.remove(id);
}
