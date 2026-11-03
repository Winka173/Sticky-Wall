import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:local_auth/local_auth.dart';

/// How asking for the phone's lock went.
enum UnlockResult {
  /// The owner proved it is them.
  unlocked,

  /// Cancelled, wrong finger too often, or the prompt was interrupted —
  /// worth offering again.
  failed,

  /// The phone has no screen lock (and no fingerprint or face) to ask for.
  noLock,
}

/// Asks for the phone's own fingerprint, face, PIN, pattern or password —
/// the app keeps no secret of its own, so there is nothing to forget or to
/// leak. Guarded so it simply reports [UnlockResult.noLock] where there is no
/// such thing (web, tests).
class AppLock {
  const AppLock();

  static final _auth = LocalAuthentication();

  Future<UnlockResult> authenticate(String reason) async {
    if (kIsWeb) return UnlockResult.noLock;
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        // Not sensitive like a payment: a face unlock need not be confirmed
        // with an extra tap.
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      );
      return ok ? UnlockResult.unlocked : UnlockResult.failed;
    } on LocalAuthException catch (e) {
      debugPrint('App lock: ${e.code.name} ${e.description ?? ''}');
      // Only a phone with no screen lock at all has nothing to ask for; any
      // other trouble keeps things shut (Unlock can be tried again).
      return e.code == LocalAuthExceptionCode.noCredentialsSet
          ? UnlockResult.noLock
          : UnlockResult.failed;
    } on MissingPluginException catch (e) {
      // No plugin (tests, desktop) behaves like a phone without a lock.
      debugPrint('App lock unavailable: $e');
      return UnlockResult.noLock;
    } catch (e) {
      debugPrint('App lock failed: $e');
      return UnlockResult.failed;
    }
  }
}
