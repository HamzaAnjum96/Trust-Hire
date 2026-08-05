import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../features/notifications/notification_rules.dart';
import '../models/admin.dart';
import '../models/bid.dart';
import '../models/job.dart';
import '../models/message.dart';
import '../models/notification.dart';
import '../models/premium.dart';
import '../models/rating.dart';
import '../models/wallet.dart';
import '../services/local_store.dart';

/// The notification feed for whoever is signed in, and how much of it is new.
///
/// **Holds almost no state.** The feed itself is derived on demand by
/// [NotificationRules] from the collections the other controllers already own,
/// so this stores exactly one thing per account: when they last looked. Every
/// alternative — an event table, a cached list, a per-entry read flag — is a
/// second copy of facts that already exist somewhere, and second copies are
/// what this codebase keeps having to go back and fix.
///
/// It is deliberately *not* a `ChangeNotifierProxyProvider` over the six
/// controllers it reads. That would rebuild the whole feed on every keystroke
/// in a search box halfway across the app. The screen asks for the feed when it
/// needs one, and this notifies only when the seen mark moves.
class NotificationController extends ChangeNotifier {
  NotificationController(this._store, {this.rules = const NotificationRules()});

  final LocalStore _store;
  final NotificationRules rules;

  Map<String, DateTime> _seen = <String, DateTime>{};
  String _accountId = '';

  void load() {
    final raw = _store.readString(StoreKeys.notificationsSeen);
    if (raw == null || raw.isEmpty) {
      _seen = <String, DateTime>{};
      notifyListeners();
      return;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _seen = {
      for (final entry in decoded.entries)
        entry.key: DateTime.parse(entry.value as String),
    };
    notifyListeners();
  }

  /// Which account's feed this is.
  ///
  /// Per account, not per device. Switching to Hina and back must not mark
  /// Usman's offers as read — the whole point of the demo accounts is that
  /// they are separate people.
  void setAccount(String id) {
    if (_accountId == id) return;
    _accountId = id;

    // **First sight of an account starts its clock.** Without this a demo
    // account carrying two years of seeded offers and ratings would open on a
    // badge reading 47, none of which happened while anybody was watching.
    //
    // Applied to memory synchronously and persisted in the background: this is
    // called from a provider update, which cannot be async, and an `await` here
    // would make the mark's value depend on when the write happened to land.
    if (!_seen.containsKey(id)) {
      _seen = {..._seen, id: DateTime.now()};
      unawaited(_persist());
    }

    notifyListeners();
  }

  /// When the current account last opened the feed, or null if never.
  DateTime? get seenAt => _seen[_accountId];

  /// The feed for the current account.
  ///
  /// Takes everything it needs as arguments rather than reaching for other
  /// controllers, so it stays a pure read and can be tested without a widget
  /// tree.
  List<AppNotification> feed({
    required Iterable<Job> jobs,
    required Iterable<Bid> bids,
    required Iterable<Rating> ratings,
    Iterable<Message> messages = const [],
    Wallet? wallet,
    DirectoryListing? listing,
    AccountReview? review,
    bool walletLocked = false,
    DateTime? now,
  }) => rules.forUser(
    _accountId,
    jobs: jobs,
    bids: bids,
    ratings: ratings,
    messages: messages,
    wallet: wallet,
    listing: listing,
    review: review,
    walletLocked: walletLocked,
    now: now ?? DateTime.now(),
  );

  /// How many entries in [feed] this account has not seen.
  int unseen(Iterable<AppNotification> feed) => rules.unseen(feed, seenAt);

  /// Records that the current account has now looked.
  ///
  /// Called when the feed is opened. Idempotent within the same second, which
  /// matters because opening a tab can rebuild several times.
  Future<void> markSeen({DateTime? at}) async {
    final now = at ?? DateTime.now();
    final previous = _seen[_accountId];
    if (previous != null && !now.isAfter(previous)) return;

    _seen = {..._seen, _accountId: now};
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => _store.writeString(
    StoreKeys.notificationsSeen,
    jsonEncode({
      for (final entry in _seen.entries)
        entry.key: entry.value.toIso8601String(),
    }),
  );
}
