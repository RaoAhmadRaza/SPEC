// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collections.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(zoneRepository)
final zoneRepositoryProvider = ZoneRepositoryProvider._();

final class ZoneRepositoryProvider
    extends $FunctionalProvider<ZoneRepository, ZoneRepository, ZoneRepository>
    with $Provider<ZoneRepository> {
  ZoneRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'zoneRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$zoneRepositoryHash();

  @$internal
  @override
  $ProviderElement<ZoneRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ZoneRepository create(Ref ref) {
    return zoneRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ZoneRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ZoneRepository>(value),
    );
  }
}

String _$zoneRepositoryHash() => r'e3bdcbfd8108dd5a23d828aec1a42bd2f26ba981';

/// Counts requests to start a new zone from outside screen 06 — Home's rail
/// `+`. A count rather than a flag, so every tap is a change to hear.

@ProviderFor(NewZoneRequests)
final newZoneRequestsProvider = NewZoneRequestsProvider._();

/// Counts requests to start a new zone from outside screen 06 — Home's rail
/// `+`. A count rather than a flag, so every tap is a change to hear.
final class NewZoneRequestsProvider
    extends $NotifierProvider<NewZoneRequests, int> {
  /// Counts requests to start a new zone from outside screen 06 — Home's rail
  /// `+`. A count rather than a flag, so every tap is a change to hear.
  NewZoneRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newZoneRequestsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newZoneRequestsHash();

  @$internal
  @override
  NewZoneRequests create() => NewZoneRequests();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$newZoneRequestsHash() => r'90fe4d7a3f0e078827056d46526bb08eff64b71f';

/// Counts requests to start a new zone from outside screen 06 — Home's rail
/// `+`. A count rather than a flag, so every tap is a change to hear.

abstract class _$NewZoneRequests extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Screen 06's rows in list order, with thumbs resolved into image
/// providers. Seeds the default zones and files unfiled objects first.

@ProviderFor(collectionZones)
final collectionZonesProvider = CollectionZonesProvider._();

/// Screen 06's rows in list order, with thumbs resolved into image
/// providers. Seeds the default zones and files unfiled objects first.

final class CollectionZonesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CollectionZone>>,
          List<CollectionZone>,
          Stream<List<CollectionZone>>
        >
    with
        $FutureModifier<List<CollectionZone>>,
        $StreamProvider<List<CollectionZone>> {
  /// Screen 06's rows in list order, with thumbs resolved into image
  /// providers. Seeds the default zones and files unfiled objects first.
  CollectionZonesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collectionZonesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collectionZonesHash();

  @$internal
  @override
  $StreamProviderElement<List<CollectionZone>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CollectionZone>> create(Ref ref) {
    return collectionZones(ref);
  }
}

String _$collectionZonesHash() => r'343206565918b072fcc6e77122735d6d3c7d9f83';
