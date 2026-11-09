import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    show PurchaseStateWrapper;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'ms_store.dart';
import 'note_storage.dart';

/// Where a purchase stands, for the Pro sheet to explain.
enum ProStatus {
  /// Nothing under way.
  idle,

  /// Asking Google Play for the price.
  loading,

  /// Paid with a method that settles later (cash at a shop, bank transfer):
  /// Pro unlocks when Google Play confirms it, even with the app closed.
  pending,

  /// The last attempt failed (not cancelled — cancelling is just [idle]).
  failed,

  /// No store on this device, or the product could not be found.
  unavailable,
}

/// Sticky Wall Pro: one non-consumable purchase through Google Play (or the
/// App Store) that unlocks the extra papers, walls, fonts and pin styles.
/// Nothing is ever taken away from the free app, and notes made with Pro
/// things keep showing them without Pro.
///
/// The unlock is cached in [NoteStorage] so the app opens unlocked offline;
/// every start also asks the store to restore purchases, which unlocks a
/// reinstall and settles a payment that was pending, and (on Google Play)
/// asks what the account owns, so a refunded or revoked order stops
/// unlocking Pro. Without an answer from the store the cache stands.
class ProController extends ChangeNotifier {
  /// [store] is null where there is no store to buy from (web, tests): Pro
  /// then stays as cached. [addOn] is the store on Windows (the Microsoft
  /// Store), used instead of [store]. [ownership] replaces the store's own
  /// ownership query in tests: true owned, false not owned, null no answer.
  ProController(this._storage, {this._store, this._addOn, this._ownership})
    : _unlocked = _storage.proUnlocked,
      _status = _store == null && _addOn == null
          ? ProStatus.unavailable
          : ProStatus.idle;

  /// The product id to create in Play Console (Monetize → In-app products)
  /// and App Store Connect, as a non-consumable.
  static const productId = 'sticky_wall_pro';

  final NoteStorage _storage;
  final InAppPurchase? _store;
  final AddOnStore? _addOn;
  final Future<bool?> Function()? _ownership;

  /// The Microsoft Store's price for Pro, once known.
  String? _addOnPrice;

  bool _unlocked;
  ProStatus _status;
  ProductDetails? _product;
  StreamSubscription<List<PurchaseDetails>>? _updates;
  Completer<bool>? _restoring;

  bool get unlocked => _unlocked;
  ProStatus get status => _status;

  /// The price as the store formats it for this user ("49.000 ₫", "$1.99"),
  /// once known.
  String? get price => _product?.price ?? _addOnPrice;

  /// Whether a purchase can be started right now.
  bool get canBuy => (_product != null || _addOnPrice != null) && !_unlocked;

  /// Subscribes to purchase updates, looks up the price and quietly restores
  /// an earlier purchase. Never throws: without a store Pro just stays
  /// locked.
  Future<void> init() async {
    final addOn = _addOn;
    if (addOn != null) {
      await loadProduct();
      // Owning it on this account unlocks a new PC or a reinstall; a clear
      // "no" (a refund) takes a cached unlock away, as on Google Play.
      final owned = await (_ownership ?? addOn.owned)();
      if (owned == true) _unlock();
      if (owned == false && _unlocked) _revoke();
      return;
    }
    final store = _store;
    if (store == null) {
      _setStatus(ProStatus.unavailable);
      await checkOwnership();
      return;
    }
    _updates = store.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        debugPrint('Purchase updates failed: $e');
        _setStatus(ProStatus.failed);
      },
    );
    await loadProduct();
    try {
      await store.restorePurchases();
    } catch (e) {
      debugPrint('Restore at start skipped: $e');
    }
    await checkOwnership();
  }

  /// Asks the store whether this account still owns Pro. Only a clear "no"
  /// takes a cached unlock away (a refund, a cancelled or charged-back
  /// order); being offline, Play being missing or an error keeps it, so a
  /// paying user is never locked out by a bad connection. Notes keep their
  /// Pro look either way; only choosing Pro things stops.
  Future<void> checkOwnership() async {
    if (!_unlocked) return;
    final owned = await (_ownership ?? _addOn?.owned ?? _playOwnership)();
    if (owned == false) _revoke();
  }

  /// Google Play's own list of what the account holds.
  Future<bool?> _playOwnership() async {
    final store = _store;
    if (store == null ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final android = store
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await android.queryPastPurchases();
      if (response.error != null) return null;
      return response.pastPurchases.any(
        (p) =>
            p.productID == productId &&
            p.billingClientPurchase.purchaseState ==
                PurchaseStateWrapper.purchased,
      );
    } catch (e) {
      debugPrint('Ownership check skipped: $e');
      return null;
    }
  }

  void _revoke() {
    _unlocked = false;
    unawaited(_storage.setProUnlocked(false));
    notifyListeners();
  }

  /// Asks the store for the product (and so its price); the Pro sheet calls
  /// it again when it opens after a failed look-up.
  Future<void> loadProduct() async {
    final addOn = _addOn;
    if (addOn != null) {
      if (_addOnPrice != null) return;
      _setStatus(ProStatus.loading);
      _addOnPrice = await addOn.price();
      _setStatus(_addOnPrice == null ? ProStatus.unavailable : ProStatus.idle);
      return;
    }
    final store = _store;
    if (store == null || _product != null) return;
    _setStatus(ProStatus.loading);
    try {
      if (!await store.isAvailable()) {
        _setStatus(ProStatus.unavailable);
        return;
      }
      final response = await store.queryProductDetails({productId});
      _product = response.productDetails
          .where((p) => p.id == productId)
          .firstOrNull;
      _setStatus(_product == null ? ProStatus.unavailable : ProStatus.idle);
    } catch (e) {
      debugPrint('Pro product look-up failed: $e');
      _setStatus(ProStatus.unavailable);
    }
  }

  /// Opens the store's payment sheet. The outcome arrives through the
  /// purchase stream ([unlocked], [status]).
  Future<void> buy() async {
    final addOn = _addOn;
    if (addOn != null) {
      if (_addOnPrice == null || _unlocked) return;
      _setStatus(ProStatus.idle);
      switch (await addOn.buy()) {
        case AddOnPurchase.purchased || AddOnPurchase.alreadyOwned:
          _unlock();
        case AddOnPurchase.cancelled:
          _setStatus(ProStatus.idle);
        case AddOnPurchase.failed:
          _setStatus(ProStatus.failed);
      }
      return;
    }
    final store = _store;
    final product = _product;
    if (store == null || product == null || _unlocked) return;
    _setStatus(ProStatus.idle);
    try {
      await store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      debugPrint('Purchase did not start: $e');
      _setStatus(ProStatus.failed);
    }
  }

  /// Asks the store for purchases made before (new phone, reinstall).
  /// Returns whether Pro is unlocked afterwards.
  Future<bool> restore() async {
    final addOn = _addOn;
    if (addOn != null) {
      if (await addOn.owned() == true) _unlock();
      return _unlocked;
    }
    final store = _store;
    if (store == null) return _unlocked;
    if (_unlocked) return true;
    final done = _restoring = Completer<bool>();
    try {
      await store.restorePurchases();
    } catch (e) {
      debugPrint('Restore failed: $e');
      _restoring = null;
      return false;
    }
    // Google Play answers with one update (empty when nothing was bought);
    // the App Store says nothing at all then, hence the time limit.
    return done.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => _unlocked,
    );
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;
      final status = _settled(purchase);
      switch (status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _unlock();
        case PurchaseStatus.pending:
          if (!_unlocked) _setStatus(ProStatus.pending);
        case PurchaseStatus.error:
          debugPrint('Purchase failed: ${purchase.error}');
          _setStatus(ProStatus.failed);
        case PurchaseStatus.canceled:
          _setStatus(ProStatus.idle);
      }
      // Google Play refunds a purchase that is not acknowledged within three
      // days; completing it is that acknowledgement. One still waiting for
      // its payment cannot be acknowledged yet.
      if (purchase.pendingCompletePurchase &&
          status != PurchaseStatus.pending) {
        try {
          await _store?.completePurchase(purchase);
        } catch (e) {
          debugPrint('Completing the purchase failed: $e');
        }
      }
    }
    final restoring = _restoring;
    if (restoring != null && !restoring.isCompleted) {
      _restoring = null;
      restoring.complete(_unlocked);
    }
  }

  /// The status to act on. Google Play reports every purchase it holds as
  /// "restored", including one still waiting for a cash or bank payment:
  /// that one is pending, not bought.
  static PurchaseStatus _settled(PurchaseDetails purchase) {
    final status = purchase.status;
    if (purchase is GooglePlayPurchaseDetails &&
        (status == PurchaseStatus.purchased ||
            status == PurchaseStatus.restored) &&
        purchase.billingClientPurchase.purchaseState !=
            PurchaseStateWrapper.purchased) {
      return PurchaseStatus.pending;
    }
    return status;
  }

  void _unlock() {
    _status = ProStatus.idle;
    if (_unlocked) {
      notifyListeners();
      return;
    }
    _unlocked = true;
    unawaited(_storage.setProUnlocked(true));
    notifyListeners();
  }

  void _setStatus(ProStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  /// Unlocks without a store, for tests and screenshots.
  @visibleForTesting
  void unlockForTesting() => _unlock();

  @override
  void dispose() {
    unawaited(_updates?.cancel());
    super.dispose();
  }
}

/// Makes the [ProController] reachable from any screen, dialog or sheet (it
/// sits above the app's navigator) and rebuilds dependents when Pro unlocks.
class ProScope extends InheritedNotifier<ProController> {
  const ProScope({
    super.key,
    required ProController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller, or null where none was provided (some tests).
  static ProController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProScope>()?.notifier;

  /// Whether Pro is unlocked; false where there is no controller.
  static bool unlockedOf(BuildContext context) =>
      maybeOf(context)?.unlocked ?? false;
}
