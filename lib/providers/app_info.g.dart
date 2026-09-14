// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `SPEC 1.0.0 (1)`: the version and build the footer of Settings shows.
///
/// Read from the bundle rather than a constant so it can never drift from the
/// build the user is actually running. Kept alive: it cannot change while the
/// app is open.

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

/// `SPEC 1.0.0 (1)`: the version and build the footer of Settings shows.
///
/// Read from the bundle rather than a constant so it can never drift from the
/// build the user is actually running. Kept alive: it cannot change while the
/// app is open.

final class AppVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// `SPEC 1.0.0 (1)`: the version and build the footer of Settings shows.
  ///
  /// Read from the bundle rather than a constant so it can never drift from the
  /// build the user is actually running. Kept alive: it cannot change while the
  /// app is open.
  AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return appVersion(ref);
  }
}

String _$appVersionHash() => r'c872504f324f5c9431b9b3e9da4a4049230332e2';
