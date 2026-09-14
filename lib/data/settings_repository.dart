import 'package:shared_preferences/shared_preferences.dart';

/// Keys are namespaced so they never collide with a plugin's own storage.
const _onboardingDoneKey = 'spec.onboarding_done';

/// The small handful of launch-time flags SPEC remembers.
///
/// Deliberately not a database. There is one boolean here, and platform
/// preferences are exactly the native feature for that.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  Future<bool> isOnboardingDone() async =>
      await _prefs.getBool(_onboardingDoneKey) ?? false;

  Future<void> setOnboardingDone() => _prefs.setBool(_onboardingDoneKey, true);

  /// Removed rather than set false, so a wiped app is indistinguishable from
  /// a fresh install.
  Future<void> resetOnboarding() => _prefs.remove(_onboardingDoneKey);
}
