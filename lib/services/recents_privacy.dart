import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the notes out of the phone's recent-apps screen while they are
/// meant to be private: the app lock is on, or a private board is open.
/// Android only (MainActivity); elsewhere it does nothing.
class RecentsPrivacy {
  RecentsPrivacy._();

  static const _channel = MethodChannel('sticky_wall/privacy');
  static bool? _hidden;

  static Future<void> hide(bool hidden) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_hidden == hidden) return;
    _hidden = hidden;
    try {
      await _channel.invokeMethod<void>('hideInRecents', hidden);
    } on MissingPluginException {
      // Tests and desktop runs have no activity to ask.
    } on PlatformException catch (e) {
      debugPrint('Could not change the recents preview: $e');
    }
  }
}
