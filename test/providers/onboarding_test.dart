import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spec/providers/onboarding.dart';

import '../support/prefs.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('a fresh install has not completed onboarding', () async {
    useInMemoryPrefs();

    await expectLater(
      _container().read(onboardingCompletedProvider.future),
      completion(isFalse),
    );
  });

  test('completing onboarding survives a relaunch', () async {
    // One store, two containers: the second stands in for the next launch.
    useInMemoryPrefs();

    final first = _container();
    await first.read(onboardingCompletedProvider.future);
    await first.read(onboardingCompletedProvider.notifier).complete();
    expect(first.read(onboardingCompletedProvider).value, isTrue);

    final relaunched = _container();

    await expectLater(
      relaunched.read(onboardingCompletedProvider.future),
      completion(isTrue),
    );
  });

  test(
    'resetting onboarding clears the flag and survives a relaunch',
    () async {
      // Arrange
      useInMemoryPrefs(initial: {'spec.onboarding_done': true});
      final first = _container();
      await first.read(onboardingCompletedProvider.future);

      // Act
      await first.read(onboardingCompletedProvider.notifier).reset();

      // Assert
      expect(first.read(onboardingCompletedProvider).value, isFalse);
      expect(
        await SharedPreferencesAsync().containsKey('spec.onboarding_done'),
        isFalse,
      );
      await expectLater(
        _container().read(onboardingCompletedProvider.future),
        completion(isFalse),
      );
    },
  );
}
