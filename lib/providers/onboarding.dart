import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spec/providers/settings.dart';

part 'onboarding.g.dart';

/// Whether the user has been through onboarding.
///
/// Read once at launch and cached, so the router's redirect can answer
/// synchronously after the first frame.
@Riverpod(keepAlive: true)
class OnboardingCompleted extends _$OnboardingCompleted {
  @override
  Future<bool> build() =>
      ref.watch(settingsRepositoryProvider).isOnboardingDone();

  /// SKIP, LATER, and finishing the first object all land here.
  Future<void> complete() async {
    await ref.read(settingsRepositoryProvider).setOnboardingDone();
    state = const AsyncData(true);
  }

  /// Delete Everything lands here. The router redirects to welcome as soon as
  /// the state flips, so callers do this last.
  Future<void> reset() async {
    await ref.read(settingsRepositoryProvider).resetOnboarding();
    state = const AsyncData(false);
  }
}
