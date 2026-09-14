// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cold-start work the splash waits on.
///
/// Opening the database and reading the onboarding flag. The splash already
/// guards this with a timeout and an error handler, so a slow or failed open
/// extends the splash rather than stranding it.

@ProviderFor(appStartup)
final appStartupProvider = AppStartupProvider._();

/// Cold-start work the splash waits on.
///
/// Opening the database and reading the onboarding flag. The splash already
/// guards this with a timeout and an error handler, so a slow or failed open
/// extends the splash rather than stranding it.

final class AppStartupProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Cold-start work the splash waits on.
  ///
  /// Opening the database and reading the onboarding flag. The splash already
  /// guards this with a timeout and an error handler, so a slow or failed open
  /// extends the splash rather than stranding it.
  AppStartupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStartupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStartupHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return appStartup(ref);
  }
}

String _$appStartupHash() => r'833d1854612251a1883873c0987d82678daa76e7';
