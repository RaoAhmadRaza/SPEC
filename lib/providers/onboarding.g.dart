// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user has been through onboarding.
///
/// Read once at launch and cached, so the router's redirect can answer
/// synchronously after the first frame.

@ProviderFor(OnboardingCompleted)
final onboardingCompletedProvider = OnboardingCompletedProvider._();

/// Whether the user has been through onboarding.
///
/// Read once at launch and cached, so the router's redirect can answer
/// synchronously after the first frame.
final class OnboardingCompletedProvider
    extends $AsyncNotifierProvider<OnboardingCompleted, bool> {
  /// Whether the user has been through onboarding.
  ///
  /// Read once at launch and cached, so the router's redirect can answer
  /// synchronously after the first frame.
  OnboardingCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingCompletedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingCompletedHash();

  @$internal
  @override
  OnboardingCompleted create() => OnboardingCompleted();
}

String _$onboardingCompletedHash() =>
    r'7124a428189c726739b1251b7a4894d405561ef5';

/// Whether the user has been through onboarding.
///
/// Read once at launch and cached, so the router's redirect can answer
/// synchronously after the first frame.

abstract class _$OnboardingCompleted extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
