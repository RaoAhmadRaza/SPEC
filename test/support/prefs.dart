import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Points shared_preferences at an in-memory store for the duration of a test.
///
/// Without it, `SharedPreferencesAsync` throws because no platform
/// implementation is registered outside a real app.
void useInMemoryPrefs({Map<String, Object>? initial}) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(initial ?? <String, Object>{});
}
