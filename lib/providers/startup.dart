import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/onboarding.dart';

part 'startup.g.dart';

/// Cold-start work the splash waits on.
///
/// Opening the database and reading the onboarding flag. The splash already
/// guards this with a timeout and an error handler, so a slow or failed open
/// extends the splash rather than stranding it.
@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) async {
  await ref.watch(specDatabaseProvider.future);
  await ref.watch(onboardingCompletedProvider.future);
}
