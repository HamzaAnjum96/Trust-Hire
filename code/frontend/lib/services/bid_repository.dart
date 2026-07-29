import '../models/bid.dart';
import 'backend/remote_api.dart';
import 'local_store.dart';

/// Reads and writes bids.
///
/// The same shape as [JobRepository]: an interface the app talks to, backed by
/// local storage until P1-8 puts a real database behind it. Nothing above this
/// line knows where bids live.
class BidRepository {
  const BidRepository(this._store, [this._queue]);

  final LocalStore _store;

  /// Where a write goes once it is on the device. See [QueueWrite].
  final QueueWrite? _queue;

  Future<List<Bid>> fetchBids() async {
    final stored = _store.readCollection(StoreKeys.bids) ?? const [];
    return stored.map(Bid.fromJson).toList(growable: false);
  }

  Future<List<Bid>> bidsFor(String jobId) async {
    final all = await fetchBids();
    return all.where((bid) => bid.jobId == jobId).toList(growable: false);
  }

  Future<void> saveBid(Bid bid) async {
    final all = [...await fetchBids()];
    final index = all.indexWhere((b) => b.id == bid.id);

    if (index == -1) {
      all.add(bid);
    } else {
      all[index] = bid;
    }

    await _write(all, changed: [bid]);
  }

  /// Writes several bids at once.
  ///
  /// Accepting a bid changes every other bid on the job, and doing that one
  /// save at a time would leave storage briefly holding two accepted bids —
  /// a state nothing downstream is prepared for.
  Future<void> saveAll(List<Bid> bids) async {
    if (bids.isEmpty) return;

    final byId = {for (final bid in await fetchBids()) bid.id: bid};
    for (final bid in bids) {
      byId[bid.id] = bid;
    }

    await _write(byId.values.toList(), changed: bids);
  }

  Future<void> deleteBidsFor(String jobId) async {
    final remaining = (await fetchBids())
        .where((bid) => bid.jobId != jobId)
        .toList();

    await _write(remaining);
  }

  Future<void> _write(List<Bid> bids, {Iterable<Bid> changed = const []}) async {
    await _store.writeCollection(
      StoreKeys.bids,
      bids.map((bid) => bid.toJson()).toList(),
    );

    // Only what changed. Accepting an offer rewrites every bid on the job, and
    // queueing all of them would offer the server a dozen writes for one act.
    final now = DateTime.now();
    for (final bid in changed) {
      await _queue?.call(
        PendingWrite(
          entity: RemoteEntity.bid,
          id: bid.id,
          data: bid.toJson(),
          madeAt: now,
        ),
      );
    }
  }
}
