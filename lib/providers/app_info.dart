import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info.g.dart';

/// `SPEC 1.0.1 (2)`: the version and build the footer of Settings shows.
///
/// Read from the bundle rather than a constant so it can never drift from the
/// build the user is actually running. Kept alive: it cannot change while the
/// app is open.
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'SPEC ${info.version} (${info.buildNumber})';
}
