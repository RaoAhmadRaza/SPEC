// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Everything Home renders, newest first, with photo file names already
/// resolved into image providers.

@ProviderFor(homeObjects)
final homeObjectsProvider = HomeObjectsProvider._();

/// Everything Home renders, newest first, with photo file names already
/// resolved into image providers.

final class HomeObjectsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HomeObject>>,
          List<HomeObject>,
          Stream<List<HomeObject>>
        >
    with $FutureModifier<List<HomeObject>>, $StreamProvider<List<HomeObject>> {
  /// Everything Home renders, newest first, with photo file names already
  /// resolved into image providers.
  HomeObjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeObjectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeObjectsHash();

  @$internal
  @override
  $StreamProviderElement<List<HomeObject>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<HomeObject>> create(Ref ref) {
    return homeObjects(ref);
  }
}

String _$homeObjectsHash() => r'39bd961f19f667fcc7ec1e7abbf099ec37b9d738';

/// The zone rail: the same zones, counts and names as Search's
/// `BROWSE BY ZONE`, so the two can never disagree.

@ProviderFor(homeCategories)
final homeCategoriesProvider = HomeCategoriesProvider._();

/// The zone rail: the same zones, counts and names as Search's
/// `BROWSE BY ZONE`, so the two can never disagree.

final class HomeCategoriesProvider
    extends
        $FunctionalProvider<
          List<HomeCategory>,
          List<HomeCategory>,
          List<HomeCategory>
        >
    with $Provider<List<HomeCategory>> {
  /// The zone rail: the same zones, counts and names as Search's
  /// `BROWSE BY ZONE`, so the two can never disagree.
  HomeCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeCategoriesHash();

  @$internal
  @override
  $ProviderElement<List<HomeCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<HomeCategory> create(Ref ref) {
    return homeCategories(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HomeCategory> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HomeCategory>>(value),
    );
  }
}

String _$homeCategoriesHash() => r'c5543f169827c3efb85c29b00e5e1e037e8e17b5';
