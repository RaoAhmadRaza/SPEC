// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(backupService)
final backupServiceProvider = BackupServiceProvider._();

final class BackupServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<BackupService>,
          BackupService,
          FutureOr<BackupService>
        >
    with $FutureModifier<BackupService>, $FutureProvider<BackupService> {
  BackupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupServiceHash();

  @$internal
  @override
  $FutureProviderElement<BackupService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BackupService> create(Ref ref) {
    return backupService(ref);
  }
}

String _$backupServiceHash() => r'3c24578139fd380c52cf4d561e3426e9658db0ea';

/// The data-control actions a screen can trigger: export, restore, wipe.
///
/// A notifier rather than bare functions so each action can also reset the
/// app state that depends on the data — recent searches, the zone list, the
/// onboarding flag — in the right order.

@ProviderFor(BackupActions)
final backupActionsProvider = BackupActionsProvider._();

/// The data-control actions a screen can trigger: export, restore, wipe.
///
/// A notifier rather than bare functions so each action can also reset the
/// app state that depends on the data — recent searches, the zone list, the
/// onboarding flag — in the right order.
final class BackupActionsProvider
    extends $NotifierProvider<BackupActions, void> {
  /// The data-control actions a screen can trigger: export, restore, wipe.
  ///
  /// A notifier rather than bare functions so each action can also reset the
  /// app state that depends on the data — recent searches, the zone list, the
  /// onboarding flag — in the right order.
  BackupActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupActionsHash();

  @$internal
  @override
  BackupActions create() => BackupActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$backupActionsHash() => r'df7f534cadfbfb558c2d57362458a70b07a0765f';

/// The data-control actions a screen can trigger: export, restore, wipe.
///
/// A notifier rather than bare functions so each action can also reset the
/// app state that depends on the data — recent searches, the zone list, the
/// onboarding flag — in the right order.

abstract class _$BackupActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
