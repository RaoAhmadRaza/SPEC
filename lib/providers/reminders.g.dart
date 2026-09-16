// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminders.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden with a fake in tests, which have no platform channel.

@ProviderFor(reminderScheduler)
final reminderSchedulerProvider = ReminderSchedulerProvider._();

/// Overridden with a fake in tests, which have no platform channel.

final class ReminderSchedulerProvider
    extends
        $FunctionalProvider<
          ReminderScheduler,
          ReminderScheduler,
          ReminderScheduler
        >
    with $Provider<ReminderScheduler> {
  /// Overridden with a fake in tests, which have no platform channel.
  ReminderSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSchedulerHash();

  @$internal
  @override
  $ProviderElement<ReminderScheduler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReminderScheduler create(Ref ref) {
    return reminderScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderScheduler>(value),
    );
  }
}

String _$reminderSchedulerHash() => r'a5941753a8a191312dee9a8350697a30ca5f818a';

/// Keeps the pending notifications in step with the objects table.
///
/// Watches the table itself rather than hooking each write, so add, edit,
/// REPLACED, delete, restore and delete-everything are all covered by one
/// listener. The table, not `ObjectRepository.watchAll`, because summaries
/// do not carry the reminder columns.
///
/// Read once from the app root and kept alive. Nothing awaits it: a failure
/// here costs a notification, never the launch.

@ProviderFor(reminderSync)
final reminderSyncProvider = ReminderSyncProvider._();

/// Keeps the pending notifications in step with the objects table.
///
/// Watches the table itself rather than hooking each write, so add, edit,
/// REPLACED, delete, restore and delete-everything are all covered by one
/// listener. The table, not `ObjectRepository.watchAll`, because summaries
/// do not carry the reminder columns.
///
/// Read once from the app root and kept alive. Nothing awaits it: a failure
/// here costs a notification, never the launch.

final class ReminderSyncProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Keeps the pending notifications in step with the objects table.
  ///
  /// Watches the table itself rather than hooking each write, so add, edit,
  /// REPLACED, delete, restore and delete-everything are all covered by one
  /// listener. The table, not `ObjectRepository.watchAll`, because summaries
  /// do not carry the reminder columns.
  ///
  /// Read once from the app root and kept alive. Nothing awaits it: a failure
  /// here costs a notification, never the launch.
  ReminderSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSyncHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return reminderSync(ref);
  }
}

String _$reminderSyncHash() => r'4cc2219af3dc8f57c5fb1fdd98708ab5cbc98890';
