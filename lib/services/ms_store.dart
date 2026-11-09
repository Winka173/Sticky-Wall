import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// How a Microsoft Store purchase ended.
enum AddOnPurchase { purchased, alreadyOwned, cancelled, failed }

/// A one-time add-on bought through a store other than Google Play: on
/// Windows, the Microsoft Store. [ProController] uses it the way it uses
/// Google Play on Android. Every call answers null (or [AddOnPurchase.failed])
/// rather than throwing when the store cannot be reached.
abstract class AddOnStore {
  /// The add-on's price as the store formats it, or null when the store or
  /// the add-on cannot be found.
  Future<String?> price();

  /// Whether this account owns the add-on; null when there is no answer.
  Future<bool?> owned();

  /// Opens the store's own purchase dialog.
  Future<AddOnPurchase> buy();
}

/// Sticky Wall Pro as a durable add-on of the Microsoft Store listing,
/// found by its Product ID ([token], the same `sticky_wall_pro` as on Google
/// Play). The Windows runner answers on the `sticky_wall/ms_store` channel
/// with `Windows.Services.Store` (windows/runner/ms_store.cpp). It works
/// only in the packaged app with the Store listing's identity; anywhere
/// else the store answers nothing and Pro stays as cached.
class MsStoreAddOn implements AddOnStore {
  const MsStoreAddOn(this.token);

  final String token;

  static const _channel = MethodChannel('sticky_wall/ms_store');

  Future<T?> _call<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method, token);
    } on PlatformException catch (e) {
      debugPrint('Microsoft Store $method failed: ${e.code} ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<String?> price() => _call<String>('price');

  @override
  Future<bool?> owned() => _call<bool>('owned');

  @override
  Future<AddOnPurchase> buy() async => switch (await _call<String>('buy')) {
    'purchased' => AddOnPurchase.purchased,
    'alreadyPurchased' => AddOnPurchase.alreadyOwned,
    'notPurchased' => AddOnPurchase.cancelled,
    _ => AddOnPurchase.failed,
  };
}
