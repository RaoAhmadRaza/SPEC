// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The open database. Awaited by `appStartup`, so it is resolved before any
/// screen builds — which is what lets the repositories below read it
/// synchronously.

@ProviderFor(specDatabase)
final specDatabaseProvider = SpecDatabaseProvider._();

/// The open database. Awaited by `appStartup`, so it is resolved before any
/// screen builds — which is what lets the repositories below read it
/// synchronously.

final class SpecDatabaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<SpecDatabase>,
          SpecDatabase,
          FutureOr<SpecDatabase>
        >
    with $FutureModifier<SpecDatabase>, $FutureProvider<SpecDatabase> {
  /// The open database. Awaited by `appStartup`, so it is resolved before any
  /// screen builds — which is what lets the repositories below read it
  /// synchronously.
  SpecDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'specDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$specDatabaseHash();

  @$internal
  @override
  $FutureProviderElement<SpecDatabase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SpecDatabase> create(Ref ref) {
    return specDatabase(ref);
  }
}

String _$specDatabaseHash() => r'8f332e7eb511bc9ca9e2bb5fcb5be1bec958d72c';

@ProviderFor(objectRepository)
final objectRepositoryProvider = ObjectRepositoryProvider._();

final class ObjectRepositoryProvider
    extends
        $FunctionalProvider<
          ObjectRepository,
          ObjectRepository,
          ObjectRepository
        >
    with $Provider<ObjectRepository> {
  ObjectRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'objectRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$objectRepositoryHash();

  @$internal
  @override
  $ProviderElement<ObjectRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ObjectRepository create(Ref ref) {
    return objectRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ObjectRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ObjectRepository>(value),
    );
  }
}

String _$objectRepositoryHash() => r'f4c26dc7dcd3b274c7f57f194d75ae47b9892f09';

@ProviderFor(searchService)
final searchServiceProvider = SearchServiceProvider._();

final class SearchServiceProvider
    extends $FunctionalProvider<SearchService, SearchService, SearchService>
    with $Provider<SearchService> {
  SearchServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchServiceHash();

  @$internal
  @override
  $ProviderElement<SearchService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchService create(Ref ref) {
    return searchService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchService>(value),
    );
  }
}

String _$searchServiceHash() => r'e45665a6e8487980559a292624a36714410c09ab';
