import '../../models/bid.dart';
import '../../models/job.dart';
import '../../models/worker_profile.dart';
import '../feed/job_visibility.dart';

/// Why a worker cannot bid on a job right now.
enum BidRefusal {
  /// The job is not in this worker's feed at all — wrong tag, or too far.
  /// Section 8's whole point: they should not be bidding on it.
  notVisible,

  /// The hirer has already chosen someone.
  alreadyAccepted,

  /// A hirer cannot bid on their own posting.
  ownJob,

  /// A fare of zero or less. Not a price, and a worker who typed one has
  /// almost certainly mistyped.
  fareNotPositive,

  /// The wallet is locked: two unpaid jobs, so no new leads until it clears
  /// (Section 11).
  walletLocked,

  /// Absurdly high. Not a rule the spec asks for, but a mistyped extra zero
  /// on a Rs. 2,000 job is a Rs. 20,000 bid, and a hirer scanning a list
  /// should not have to catch that for them.
  fareImplausible,
}

/// The rules around offering and accepting a fare (Section 4).
///
/// Kept as pure functions over plain data, like [JobVisibility] — this decides
/// what people are paid, and it should be checkable without a widget or a
/// database.
class BiddingRules {
  const BiddingRules({this.visibility = const JobVisibility()});

  final JobVisibility visibility;

  /// The most a bid may exceed the starting fare. Section 4 sets no ceiling;
  /// this one exists to catch a mistyped zero, so it is deliberately loose.
  static const implausibleMultiple = 10;

  /// A floor for jobs posted without a starting fare, so the multiple above
  /// still means something.
  static const implausibleFloor = 100000;

  /// Whether [worker] may bid on [job], and why not when they may not.
  BidRefusal? refusalFor(
    Job job, {
    required WorkerProfile worker,
    JobLocation? from,
    required List<Bid> existingBids,
    bool walletLocked = false,
  }) {
    if (job.isLocal) return BidRefusal.ownJob;
    // Checked before visibility: a locked worker should be told why they
    // cannot bid, not left to wonder whether the job simply moved.
    if (walletLocked) return BidRefusal.walletLocked;
    // The job's own status is the authority from P1-3 — a job can stop taking
    // offers by being cancelled or expiring, not only by being accepted.
    if (!job.status.isTakingOffers ||
        existingBids.any((b) => b.status == BidStatus.accepted)) {
      return BidRefusal.alreadyAccepted;
    }
    if (!visibility.isVisibleTo(job, worker: worker, from: from)) {
      return BidRefusal.notVisible;
    }
    return null;
  }

  bool canBid(
    Job job, {
    required WorkerProfile worker,
    JobLocation? from,
    required List<Bid> existingBids,
    bool walletLocked = false,
  }) {
    return refusalFor(
          job,
          worker: worker,
          from: from,
          existingBids: existingBids,
          walletLocked: walletLocked,
        ) ==
        null;
  }

  /// Whether a fare is a number a person could have meant.
  BidRefusal? refusalForFare(int fare, {int? startingFare}) {
    if (fare <= 0) return BidRefusal.fareNotPositive;

    final ceiling = startingFare == null
        ? implausibleFloor
        : startingFare * implausibleMultiple;
    if (fare > ceiling) return BidRefusal.fareImplausible;

    return null;
  }

  /// Bids to show the hirer, best-known-first.
  ///
  /// Cheapest first, and ties broken by who offered first. Deliberately *not*
  /// a recommendation: Section 4 requires the hirer to choose, so this only
  /// decides reading order. Accepting the top row is never automatic, and no
  /// row is marked as the one to take.
  List<Bid> forReview(List<Bid> bids) {
    final open = bids.where((b) => b.status != BidStatus.withdrawn).toList();
    open.sort((a, b) {
      final byFare = a.fare.compareTo(b.fare);
      return byFare != 0 ? byFare : a.createdAt.compareTo(b.createdAt);
    });
    return List.unmodifiable(open);
  }

  /// The result of a hirer choosing [accepted].
  ///
  /// Returns every bid on the job with its new status, so the caller writes
  /// one consistent set rather than mutating them one at a time — a job with
  /// two accepted bids is a state the app must not be able to reach.
  List<Bid> accept(Bid accepted, {required List<Bid> allBidsOnJob}) {
    return List.unmodifiable([
      for (final bid in allBidsOnJob)
        if (bid.id == accepted.id)
          bid.copyWith(status: BidStatus.accepted)
        else if (bid.status == BidStatus.withdrawn)
          bid
        else
          bid.copyWith(status: BidStatus.passedOver),
    ]);
  }
}
