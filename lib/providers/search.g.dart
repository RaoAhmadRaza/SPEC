// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The queries the user ran, newest first.
///
/// Deliberately not persisted: a search history that outlives the session is
/// a record of what someone was looking for, and SPEC keeps none.

@ProviderFor(RecentQueries)
final recentQueriesProvider = RecentQueriesProvider._();

/// The queries the user ran, newest first.
///
/// Deliberately not persisted: a search history that outlives the session is
/// a record of what someone was looking for, and SPEC keeps none.
final class RecentQueriesProvider
    extends $NotifierProvider<RecentQueries, List<String>> {
  /// The queries the user ran, newest first.
  ///
  /// Deliberately not persisted: a search history that outlives the session is
  /// a record of what someone was looking for, and SPEC keeps none.
  RecentQueriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentQueriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentQueriesHash();

  @$internal
  @override
  RecentQueries create() => RecentQueries();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$recentQueriesHash() => r'4ad5bd3db71bafe3be15dd93ba9704ad72e5e2c8';

/// The queries the user ran, newest first.
///
/// Deliberately not persisted: a search history that outlives the session is
/// a record of what someone was looking for, and SPEC keeps none.

abstract class _$RecentQueries extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// `41 OBJECTS · 96 PHOTOS`.

@ProviderFor(archiveCounts)
final archiveCountsProvider = ArchiveCountsProvider._();

/// `41 OBJECTS · 96 PHOTOS`.

final class ArchiveCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ArchiveCounts>,
          ArchiveCounts,
          Stream<ArchiveCounts>
        >
    with $FutureModifier<ArchiveCounts>, $StreamProvider<ArchiveCounts> {
  /// `41 OBJECTS · 96 PHOTOS`.
  ArchiveCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archiveCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archiveCountsHash();

  @$internal
  @override
  $StreamProviderElement<ArchiveCounts> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ArchiveCounts> create(Ref ref) {
    return archiveCounts(ref);
  }
}

String _$archiveCountsHash() => r'a9cb8c479910cd44c0093f9c7ac9b794eaf3d06d';

/// `BROWSE BY ZONE`. Derived from the objects themselves rather than from the
/// zones table, because nothing creates zones yet.

@ProviderFor(searchZones)
final searchZonesProvider = SearchZonesProvider._();

/// `BROWSE BY ZONE`. Derived from the objects themselves rather than from the
/// zones table, because nothing creates zones yet.

final class SearchZonesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SearchZone>>,
          List<SearchZone>,
          Stream<List<SearchZone>>
        >
    with $FutureModifier<List<SearchZone>>, $StreamProvider<List<SearchZone>> {
  /// `BROWSE BY ZONE`. Derived from the objects themselves rather than from the
  /// zones table, because nothing creates zones yet.
  SearchZonesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchZonesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchZonesHash();

  @$internal
  @override
  $StreamProviderElement<List<SearchZone>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SearchZone>> create(Ref ref) {
    return searchZones(ref);
  }
}

String _$searchZonesHash() => r'c31f3b2b60dc80a7e0231ac5b5fdd4ddaf3dd532';

/// Fires whenever an object is added, edited or deleted.
///
/// The runner rebuilds on it, and screen 02 re-runs its query when the runner
/// changes, so results never outlive the rows they were read from.

@ProviderFor(searchArchive)
final searchArchiveProvider = SearchArchiveProvider._();

/// Fires whenever an object is added, edited or deleted.
///
/// The runner rebuilds on it, and screen 02 re-runs its query when the runner
/// changes, so results never outlive the rows they were read from.

final class SearchArchiveProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ObjectSummary>>,
          List<ObjectSummary>,
          Stream<List<ObjectSummary>>
        >
    with
        $FutureModifier<List<ObjectSummary>>,
        $StreamProvider<List<ObjectSummary>> {
  /// Fires whenever an object is added, edited or deleted.
  ///
  /// The runner rebuilds on it, and screen 02 re-runs its query when the runner
  /// changes, so results never outlive the rows they were read from.
  SearchArchiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchArchiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchArchiveHash();

  @$internal
  @override
  $StreamProviderElement<List<ObjectSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ObjectSummary>> create(Ref ref) {
    return searchArchive(ref);
  }
}

String _$searchArchiveHash() => r'225900bbf5ea56ecb3115c31a1cc89cf7c93ffa5';

/// The runner screen 02 hands each keystroke to.
///
/// [isListingAll] is SEE ALL on Home: a blank query lists the whole archive.

@ProviderFor(searchQueryRunner)
final searchQueryRunnerProvider = SearchQueryRunnerFamily._();

/// The runner screen 02 hands each keystroke to.
///
/// [isListingAll] is SEE ALL on Home: a blank query lists the whole archive.

final class SearchQueryRunnerProvider
    extends
        $FunctionalProvider<
          AsyncValue<SearchQueryRunner>,
          SearchQueryRunner,
          FutureOr<SearchQueryRunner>
        >
    with
        $FutureModifier<SearchQueryRunner>,
        $FutureProvider<SearchQueryRunner> {
  /// The runner screen 02 hands each keystroke to.
  ///
  /// [isListingAll] is SEE ALL on Home: a blank query lists the whole archive.
  SearchQueryRunnerProvider._({
    required SearchQueryRunnerFamily super.from,
    required ({String? scope, bool isListingAll}) super.argument,
  }) : super(
         retry: null,
         name: r'searchQueryRunnerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchQueryRunnerHash();

  @override
  String toString() {
    return r'searchQueryRunnerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<SearchQueryRunner> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SearchQueryRunner> create(Ref ref) {
    final argument = this.argument as ({String? scope, bool isListingAll});
    return searchQueryRunner(
      ref,
      scope: argument.scope,
      isListingAll: argument.isListingAll,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchQueryRunnerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchQueryRunnerHash() => r'11fa0e0183dd54a5fdf117bbe6be7a1fc9eea2c4';

/// The runner screen 02 hands each keystroke to.
///
/// [isListingAll] is SEE ALL on Home: a blank query lists the whole archive.

final class SearchQueryRunnerFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SearchQueryRunner>,
          ({String? scope, bool isListingAll})
        > {
  SearchQueryRunnerFamily._()
    : super(
        retry: null,
        name: r'searchQueryRunnerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The runner screen 02 hands each keystroke to.
  ///
  /// [isListingAll] is SEE ALL on Home: a blank query lists the whole archive.

  SearchQueryRunnerProvider call({String? scope, bool isListingAll = false}) =>
      SearchQueryRunnerProvider._(
        argument: (scope: scope, isListingAll: isListingAll),
        from: this,
      );

  @override
  String toString() => r'searchQueryRunnerProvider';
}
