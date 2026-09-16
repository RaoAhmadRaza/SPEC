import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/object/object_models.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/home.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/providers/reminders.dart';

import '../support/reminders.dart';

/// Today, as the provider sees it, minus [years].
String _yearsAgo(int years) {
  final now = DateTime.now();
  return toIsoDate(DateTime(now.year - years, now.month, now.day));
}

void main() {
  late SpecDatabase database;
  late FakeReminderScheduler scheduler;
  late ProviderContainer container;

  setUp(() {
    database = SpecDatabase.memory();
    scheduler = FakeReminderScheduler();
    final photos = Directory.systemTemp.createTempSync('spec_reminders_test');
    container = ProviderContainer(
      overrides: [
        specDatabaseProvider.overrideWith((ref) async => database),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        photoStoreProvider.overrideWith((ref) async => PhotoStore(photos)),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
      photos.deleteSync(recursive: true);
    });
  });

  Future<int> create({
    String name = 'Bulb',
    int? every,
    String? replacedOn,
  }) async {
    await container.read(specDatabaseProvider.future);
    return container
        .read(objectRepositoryProvider)
        .create(
          ObjectsCompanion.insert(
            name: name,
            type: ObjectType.product.name,
            specKind: SpecKind.model.name,
            specValue: 'B22',
            replacedOn: Value(replacedOn),
            remindEveryMonths: Value(every),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  /// Drift's watch streams and the reconcile queue both settle on later
  /// microtasks and timers, so wait on the outcome rather than a count.
  Future<void> until(bool Function() condition) async {
    for (var i = 0; i < 200 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(condition(), isTrue);
  }

  group('reminderSync', () {
    setUp(() => container.read(reminderSyncProvider.future));

    test('schedules an object with a future reminder', () async {
      final id = await create(every: 6, replacedOn: _yearsAgo(0));

      await until(() => scheduler.pending.containsKey(id));
      expect(scheduler.pending[id]!.body, 'Time to replace: Bulb · B22');
      expect(scheduler.permissionRequests, greaterThan(0));
    });

    test('an overdue reminder and no reminder schedule nothing', () async {
      await create(every: 1, replacedOn: _yearsAgo(2));
      await create(name: 'Plain');
      // Let both writes pass through the queue.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(scheduler.pending, isEmpty);
      expect(scheduler.permissionRequests, 0);
    });

    test('REPLACED moves it, clearing and deleting cancel it', () async {
      final repository = container.read(objectRepositoryProvider);
      final id = await create(every: 6, replacedOn: _yearsAgo(0));
      await until(() => scheduler.pending.containsKey(id));
      final first = scheduler.pending[id]!.fireAt;

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await repository.markReplaced(id, on: tomorrow);
      await until(() => scheduler.pending[id]?.fireAt != first);

      await (database.update(database.objects)..where((o) => o.id.equals(id)))
          .write(const ObjectsCompanion(remindEveryMonths: Value(null)));
      await until(() => scheduler.pending.isEmpty);

      await (database.update(database.objects)..where((o) => o.id.equals(id)))
          .write(const ObjectsCompanion(remindEveryMonths: Value(3)));
      await until(() => scheduler.pending.containsKey(id));

      await repository.delete(id);
      await until(() => scheduler.pending.isEmpty);
    });
  });

  test('Home marks only objects whose reminder has fallen due', () async {
    final overdue = await create(
      name: 'Old',
      every: 1,
      replacedOn: _yearsAgo(1),
    );
    await create(name: 'Fresh', every: 6, replacedOn: _yearsAgo(0));
    await create(name: 'Plain');

    final subscription = container.listen(homeObjectsProvider, (_, _) {});
    addTearDown(subscription.close);
    await until(
      () => (container.read(homeObjectsProvider).value?.length ?? 0) == 3,
    );

    final objects = container.read(homeObjectsProvider).value!;
    expect(
      {for (final object in objects) object.id: object.isDue},
      {overdue: true, overdue + 1: false, overdue + 2: false},
    );
  });
}
