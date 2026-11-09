import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/services/ms_store.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/pro_controller.dart';

/// The Microsoft Store as the test sets it up.
class _FakeStore implements AddOnStore {
  String? priceAnswer = '79.000 ₫';
  bool? ownedAnswer = false;
  AddOnPurchase buyAnswer = AddOnPurchase.purchased;
  int buys = 0;

  @override
  Future<String?> price() async => priceAnswer;

  @override
  Future<bool?> owned() async => ownedAnswer;

  @override
  Future<AddOnPurchase> buy() async {
    buys++;
    return buyAnswer;
  }
}

Future<(ProController, NoteStorage)> _pro(
  _FakeStore store, {
  bool cached = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage.setProUnlocked(cached);
  final pro = ProController(storage, addOn: store);
  await pro.init();
  return (pro, storage);
}

void main() {
  test('the price comes from the store, and buying unlocks Pro', () async {
    final store = _FakeStore();
    final (pro, storage) = await _pro(store);
    expect(pro.price, '79.000 ₫');
    expect(pro.canBuy, isTrue);
    expect(pro.unlocked, isFalse);
    await pro.buy();
    expect(store.buys, 1);
    expect(pro.unlocked, isTrue);
    expect(storage.proUnlocked, isTrue);
    expect(pro.canBuy, isFalse);
  });

  test('a cancelled purchase changes nothing; a failed one says so', () async {
    final store = _FakeStore()..buyAnswer = AddOnPurchase.cancelled;
    final (pro, _) = await _pro(store);
    await pro.buy();
    expect(pro.unlocked, isFalse);
    expect(pro.status, ProStatus.idle);
    store.buyAnswer = AddOnPurchase.failed;
    await pro.buy();
    expect(pro.unlocked, isFalse);
    expect(pro.status, ProStatus.failed);
    // Bought on another PC: the store says it is owned already.
    store.buyAnswer = AddOnPurchase.alreadyOwned;
    await pro.buy();
    expect(pro.unlocked, isTrue);
  });

  test(
    'owned on the account unlocks a new PC; a refund takes it away',
    () async {
      final (newPc, _) = await _pro(_FakeStore()..ownedAnswer = true);
      expect(newPc.unlocked, isTrue);

      final (refunded, storage) = await _pro(
        _FakeStore()..ownedAnswer = false,
        cached: true,
      );
      expect(refunded.unlocked, isFalse);
      expect(storage.proUnlocked, isFalse);
    },
  );

  test('no answer from the store keeps what was cached', () async {
    final (pro, _) = await _pro(
      _FakeStore()
        ..ownedAnswer = null
        ..priceAnswer = null,
      cached: true,
    );
    expect(pro.unlocked, isTrue);
    expect(pro.status, ProStatus.unavailable);
  });

  test('without the add-on in the store nothing can be bought', () async {
    final store = _FakeStore()..priceAnswer = null;
    final (pro, _) = await _pro(store);
    expect(pro.status, ProStatus.unavailable);
    expect(pro.canBuy, isFalse);
    await pro.buy();
    expect(store.buys, 0);
  });

  test('Restore asks the store what the account owns', () async {
    final store = _FakeStore();
    final (pro, _) = await _pro(store);
    expect(await pro.restore(), isFalse);
    store.ownedAnswer = true;
    expect(await pro.restore(), isTrue);
    expect(pro.unlocked, isTrue);
  });
}
