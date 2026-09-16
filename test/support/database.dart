import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/reminders.dart';

import 'reminders.dart';

/// Wraps [child] in a scope whose database is a real sqlite held in memory.
///
/// Without it a widget test that boots the app throws, because opening the
/// real file needs a path_provider platform implementation. Notifications go
/// to a fake for the same reason: a test has no plugin behind the channel.
Widget withInMemoryDatabase(Widget child) => ProviderScope(
  overrides: [
    specDatabaseProvider.overrideWith((ref) async {
      final database = SpecDatabase.memory();
      ref.onDispose(database.close);
      return database;
    }),
    reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
  ],
  child: child,
);
