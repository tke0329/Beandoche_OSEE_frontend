import 'dart:async';
import 'dart:js_interop';

import 'google_sdk.dart';

@JS('google.accounts.id.revoke')
external void _revoke(String hint, JSFunction callback);

Future<bool> revokeGoogleSubjects(List<String> subjects) async {
  const clientId = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');
  if (subjects.isEmpty || clientId.isEmpty) return false;
  try {
    await initializeGoogleSdk(clientId).timeout(const Duration(seconds: 10));
    var allSucceeded = true;
    for (final subject in subjects) {
      final completed = Completer<bool>();
      _revoke(
        subject,
        ((JSAny? response) {
          final result = response.dartify();
          if (!completed.isCompleted) {
            completed.complete(result is Map && result['successful'] == true);
          }
        }).toJS,
      );
      final success = await completed.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      allSucceeded = success && allSucceeded;
    }
    return allSucceeded;
  } catch (_) {
    // Observable failure: the completion screen offers manual unlink instead of claiming success.
    return false;
  }
}
