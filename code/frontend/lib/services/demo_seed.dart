import 'dart:convert';

import 'local_store.dart';
import 'seed_loader.dart';

/// Writes the parts of the seed that belong to a **person** rather than to a
/// job: offers, ratings, and each demo account's role, trades and wallet.
///
/// Its own class rather than more of [JobRepository] because the keys it
/// touches are per-account, and a repository that quietly wrote somebody's
/// wallet while saving a job would be the kind of thing nobody finds until it
/// has overwritten a balance.
///
/// **Nothing here is merged.** A reset restores the demo, which means the
/// seeded ledgers and offers replace whatever was there — the same promise the
/// jobs already make, and the reason the reset dialogue warns before it runs.
class DemoSeed {
  const DemoSeed(this._store, [this._loader = const SeedLoader()]);

  final LocalStore _store;
  final SeedLoader _loader;

  Future<void> install() async {
    await _installBids();
    await _installRatings();
    await _installAccounts();
  }

  Future<void> _installBids() async {
    final bids = await _loader.loadBids();
    await _store.writeCollection(
      StoreKeys.bids,
      bids.map((bid) => bid.toJson()).toList(growable: false),
    );
  }

  Future<void> _installRatings() async {
    final ratings = await _loader.loadRatings();
    await _store.writeCollection(
      StoreKeys.ratings,
      ratings.map((rating) => rating.toJson()).toList(growable: false),
    );
  }

  Future<void> _installAccounts() async {
    for (final account in await _loader.loadAccounts()) {
      await _store.writeString(
        StoreKeys.forAccount(StoreKeys.role, account.id),
        account.role.id,
      );
      await _store.writeString(
        StoreKeys.forAccount(StoreKeys.workerProfile, account.id),
        jsonEncode(account.profile.toJson()),
      );
      await _store.writeString(
        StoreKeys.forAccount(StoreKeys.wallet, account.id),
        jsonEncode(account.wallet.toJson()),
      );
    }
  }
}
