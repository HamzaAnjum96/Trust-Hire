import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../services/local_store.dart';

/// Who the device is currently being.
///
/// Everything that asks "is this mine?" — ownership of a job, whose bid this
/// is, whose wallet is charged, which trades filter the feed — resolves
/// through [activeId]. Changing it changes all of those at once, which is the
/// point: the two sides of a hire are the same app seen from two identities.
///
/// The active account is stored, so a reload does not silently put you back to
/// being somebody else halfway through a demonstration.
class AccountController extends ChangeNotifier {
  AccountController(this._store);

  final LocalStore _store;

  DemoAccount _active = DemoAccounts.device;
  DemoAccount get active => _active;
  String get activeId => _active.id;

  List<DemoAccount> get roster => DemoAccounts.roster;

  void load() {
    _active = DemoAccounts.byId(_store.readString(StoreKeys.activeAccount));
    notifyListeners();
  }

  Future<void> switchTo(DemoAccount account) async {
    if (account.id == _active.id) return;

    _active = account;
    notifyListeners();

    await _store.writeString(StoreKeys.activeAccount, account.id);
  }
}
