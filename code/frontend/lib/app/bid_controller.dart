import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../features/bidding/bidding_rules.dart';
import '../models/account.dart';
import '../models/bid.dart';
import '../models/job.dart';
import '../services/bid_repository.dart';

/// Holds the bids in memory and mediates every change to them.
///
/// Accepting is the one operation here that matters: it fixes what a worker
/// gets paid and what the platform later takes a commission on, so it goes
/// through [BiddingRules.accept] and is written in a single batch rather than
/// bid by bid.
class BidController extends ChangeNotifier {
  BidController(
    this._repository, {
    this.rules = const BiddingRules(),
    this.uuid = const Uuid(),
  });


  final BidRepository _repository;
  final BiddingRules rules;

  @visibleForTesting
  final Uuid uuid;

  List<Bid> _bids = const <Bid>[];
  List<Bid> get bids => _bids;

  /// Whose bids count as mine. Follows the active demo account.
  ///
  /// The bid list itself is shared: a bid records the worker who made it, so
  /// switching account changes which of them are yours rather than which of
  /// them exist. That is what lets one person bid, another accept, and both
  /// see the same offer.
  String _workerId = DemoAccounts.deviceId;
  String get workerId => _workerId;

  void setAccount(String id) {
    if (_workerId == id) return;
    _workerId = id;
    notifyListeners();
  }

  Future<void> load() async {
    _bids = await _repository.fetchBids();
    notifyListeners();
  }

  List<Bid> forJob(String jobId) =>
      _bids.where((bid) => bid.jobId == jobId).toList(growable: false);

  /// The active account's bid on a job, if it has made one.
  Bid? myBidOn(String jobId) {
    for (final bid in _bids) {
      if (bid.jobId == jobId && bid.workerId == _workerId) return bid;
    }
    return null;
  }

  /// Bids in the order the hirer should read them — cheapest first, never
  /// marked as recommended. See [BiddingRules.forReview].
  List<Bid> forReview(String jobId) => rules.forReview(forJob(jobId));

  /// Places or replaces the active account's bid.
  ///
  /// Replacing rather than adding a second: a worker who changes their mind
  /// has revised their offer, and two live bids from one person would let them
  /// occupy a hirer's list twice.
  Future<Bid?> placeBid({
    required String jobId,
    required int fare,
    String? message,
  }) async {
    final existing = myBidOn(jobId);
    if (existing != null && !existing.status.isOpen) return null;

    final trimmed = message?.trim();
    final bid = existing == null
        ? Bid(
            id: uuid.v4(),
            jobId: jobId,
            workerId: _workerId,
            fare: fare,
            createdAt: DateTime.now(),
            message: trimmed?.isEmpty ?? true ? null : trimmed,
          )
        : existing.copyWith(
            fare: fare,
            message: trimmed?.isEmpty ?? true ? null : trimmed,
            clearMessage: trimmed?.isEmpty ?? true,
            // A revised offer is a new offer, and should sit where a new
            // offer would in the hirer's list.
            createdAt: DateTime.now(),
          );

    await _repository.saveBid(bid);
    await load();
    return bid;
  }

  Future<void> withdrawBid(String jobId) async {
    final mine = myBidOn(jobId);
    if (mine == null || !mine.status.isOpen) return;

    await _repository.saveBid(mine.copyWith(status: BidStatus.withdrawn));
    await load();
  }

  /// The hirer chooses [bid]. Returns the job with its fare locked.
  ///
  /// Every other bid on the job is closed in the same write, so storage is
  /// never briefly holding two accepted bids.
  Future<Job> accept(Bid bid, {required Job job}) async {
    if (job.isAccepted) return job;

    await _repository.saveAll(rules.accept(bid, allBidsOnJob: forJob(job.id)));
    await load();

    return job.withAcceptedBid(workerId: bid.workerId, fare: bid.fare);
  }

  /// Drops the bids on a deleted job, so they cannot outlive it.
  Future<void> forgetJob(String jobId) async {
    await _repository.deleteBidsFor(jobId);
    await load();
  }
}
