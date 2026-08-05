import '../../models/bid.dart';
import '../../models/job.dart';
import '../../models/job_status.dart';
import '../../models/message.dart';
import '../../models/notification.dart';
import '../../models/premium.dart';
import '../../models/rating.dart';
import '../../models/admin.dart';
import '../../models/wallet.dart';

/// What one person needs to be told, worked out from what is already stored.
///
/// **Derived, not recorded.** The obvious design is an event table that each
/// controller appends to when something happens. It was rejected because this
/// codebase has been bitten three times by exactly that shape: a write nobody
/// makes is invisible, and the test passes because it seeds the table by hand.
/// The sync layer shipped with a full test file and no caller; `reaches` was
/// tested for two sprints while nothing could reach it.
///
/// A derived feed cannot drift from the data, because it *is* the data. Accept
/// a bid anywhere in the app — from the sheet, from a test, from a future
/// screen nobody has written — and the worker is told, because being told is
/// the same fact as the bid being accepted.
///
/// The cost is real and worth stating: there is no per-entry read state, only
/// "seen up to here". [NotificationController] stores that one timestamp.
class NotificationRules {
  const NotificationRules();

  /// Under this much time left, a subscription is worth mentioning. Long
  /// enough to renew without rushing, short enough not to nag for a year.
  static const subscriptionWarning = Duration(days: 14);

  /// Everything [userId] should know about, newest first.
  ///
  /// Every argument is the whole collection rather than a pre-filtered slice,
  /// because filtering is the part that decides what somebody is told and it
  /// belongs here where it can be tested rather than at four call sites.
  List<AppNotification> forUser(
    String userId, {
    required Iterable<Job> jobs,
    required Iterable<Bid> bids,
    required Iterable<Rating> ratings,
    required DateTime now,
    Iterable<Message> messages = const [],
    Wallet? wallet,
    DirectoryListing? listing,
    AccountReview? review,
    bool walletLocked = false,
  }) {
    final byId = {for (final job in jobs) job.id: job};
    final feed = <AppNotification>[];

    for (final job in jobs) {
      feed.addAll(_aboutJob(job, userId: userId, bids: bids));
    }

    feed.addAll(_aboutBids(bids, userId: userId, jobs: byId));
    feed.addAll(_aboutRatings(ratings, userId: userId, jobs: byId));
    feed.addAll(_aboutMessages(messages, userId: userId, jobs: byId));
    if (wallet != null) {
      feed.addAll(_aboutWallet(wallet, locked: walletLocked, now: now));
    }
    if (listing != null) feed.addAll(_aboutListing(listing, now: now));
    if (review != null) feed.addAll(_aboutVerification(review));

    // Newest first, then by id so the order is stable when two things share a
    // timestamp — which the seed guarantees, since it generates in batches.
    feed.sort((a, b) {
      final byTime = b.at.compareTo(a.at);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });

    // **Nothing dated in the future.** The seed works in offsets from the
    // moment it is read, and a scheduled job an hour from now must not appear
    // as something that already happened.
    return List.unmodifiable(feed.where((entry) => !entry.at.isAfter(now)));
  }

  /// How many of [feed] arrived after [seenAt].
  ///
  /// A null [seenAt] means this account has never opened the feed, which is
  /// not the same as everything being unread: a demo account with two years of
  /// seeded history would open on a badge reading 47. The first look counts as
  /// having seen what was already there.
  int unseen(Iterable<AppNotification> feed, DateTime? seenAt) =>
      seenAt == null ? 0 : feed.where((e) => e.at.isAfter(seenAt)).length;

  /// The lifecycle, from whichever side [userId] is on.
  Iterable<AppNotification> _aboutJob(
    Job job, {
    required String userId,
    required Iterable<Bid> bids,
  }) sync* {
    final isHirer = job.isPostedBy(userId);
    final isWorker = job.acceptedWorkerId == userId;

    // Somebody with no part in this job hears nothing about it. This is the
    // line that stops the feed being a public activity log of the whole
    // marketplace.
    if (!isHirer && !isWorker) return;

    final at = job.lastActivityAt;
    final other = isHirer ? job.acceptedWorkerId : job.postedBy;

    switch (job.status) {
      case JobStatus.open:
        break;
      case JobStatus.accepted:
        // The worker's copy of this is `offerAccepted`, raised from the bid,
        // which carries the fare. Raising it twice would tell them once with
        // the number and once without.
        break;
      case JobStatus.inProgress:
        yield AppNotification(
          id: 'job-${job.id}-started',
          kind: NotificationKind.jobStarted,
          at: at,
          jobId: job.id,
          otherPartyId: other,
        );
      case JobStatus.completed:
        yield AppNotification(
          id: 'job-${job.id}-completed',
          kind: NotificationKind.jobCompleted,
          at: at,
          jobId: job.id,
          otherPartyId: other,
          amount: job.agreedFare,
        );
      case JobStatus.cancelled:
        yield AppNotification(
          id: 'job-${job.id}-cancelled',
          kind: NotificationKind.jobCancelled,
          at: at,
          jobId: job.id,
          otherPartyId: other,
        );
      case JobStatus.expired:
        // Only the hirer. A worker who never got it does not need telling that
        // a job they could not see has gone.
        if (isHirer) {
          yield AppNotification(
            id: 'job-${job.id}-expired',
            kind: NotificationKind.jobExpired,
            at: at,
            jobId: job.id,
          );
        }
    }
  }

  /// Offers: received, won, lost.
  Iterable<AppNotification> _aboutBids(
    Iterable<Bid> bids, {
    required String userId,
    required Map<String, Job> jobs,
  }) sync* {
    for (final bid in bids) {
      final job = jobs[bid.jobId];
      if (job == null) continue;

      final isMine = bid.workerId == userId;
      final isMyJob = job.isPostedBy(userId);

      // A hirer hears about every live offer on their job. Withdrawn ones are
      // silently dropped rather than reported as arriving and leaving — the
      // worker changed their mind, which is not news.
      if (isMyJob && !isMine && bid.status != BidStatus.withdrawn) {
        yield AppNotification(
          id: 'bid-${bid.id}-received',
          kind: NotificationKind.offerReceived,
          at: bid.createdAt,
          jobId: job.id,
          otherPartyId: bid.workerId,
          amount: bid.fare,
        );
      }

      if (!isMine) continue;

      switch (bid.status) {
        case BidStatus.accepted:
          yield AppNotification(
            id: 'bid-${bid.id}-accepted',
            kind: NotificationKind.offerAccepted,
            // When the hirer chose. Not when the offer was made, which could
            // be a week earlier — and not the job's `statusChangedAt`, which
            // by the time the work is finished records *that* instead.
            at: bid.decidedAt ?? job.statusChangedAt ?? bid.createdAt,
            jobId: job.id,
            otherPartyId: job.postedBy,
            amount: bid.fare,
          );
        case BidStatus.passedOver:
          // **Said plainly.** A worker who has to refresh a job to work out
          // they lost it is being told by omission, which is the least kind
          // way to say it.
          yield AppNotification(
            id: 'bid-${bid.id}-passed',
            kind: NotificationKind.offerPassedOver,
            at: bid.decidedAt ?? job.statusChangedAt ?? bid.createdAt,
            jobId: job.id,
          );
        case BidStatus.offered || BidStatus.withdrawn:
          break;
      }
    }
  }

  /// Unread messages, one entry per thread rather than one per message.
  ///
  /// **Collapsed on purpose.** Somebody who writes nine lines in a row has
  /// asked one thing; nine identical rows in the feed would bury everything
  /// else and send the reader to the same place nine times.
  ///
  /// Read messages produce nothing at all. Unlike the rest of the feed, a
  /// message carries its own read state, so there is a better answer available
  /// than "since you last looked at Activity".
  Iterable<AppNotification> _aboutMessages(
    Iterable<Message> messages, {
    required String userId,
    required Map<String, Job> jobs,
  }) sync* {
    final newest = <String, Message>{};

    for (final message in messages) {
      if (message.senderId == userId || message.isRead) continue;

      final job = jobs[message.jobId];
      // The same boundary the rest of the feed uses: a thread belongs to the
      // two people on the job and to nobody else.
      if (job == null) continue;
      if (!job.isPostedBy(userId) && job.acceptedWorkerId != userId) continue;

      final held = newest[message.jobId];
      if (held == null || message.sentAt.isAfter(held.sentAt)) {
        newest[message.jobId] = message;
      }
    }

    for (final message in newest.values) {
      yield AppNotification(
        // Keyed by the job, not the message: the entry is about the thread,
        // and an id that moved with each new line would make "seen" useless.
        id: 'thread-${message.jobId}',
        kind: NotificationKind.messageReceived,
        at: message.sentAt,
        jobId: message.jobId,
        otherPartyId: message.senderId,
      );
    }
  }

  Iterable<AppNotification> _aboutRatings(
    Iterable<Rating> ratings, {
    required String userId,
    required Map<String, Job> jobs,
  }) sync* {
    for (final rating in ratings) {
      final job = jobs[rating.jobId];
      if (job == null) continue;

      // `side` is who was *rated*. A worker hears about their own worker-side
      // rating, a hirer about theirs — never about the one they wrote.
      final aboutMe = switch (rating.side) {
        RatedSide.worker => job.acceptedWorkerId == userId,
        RatedSide.hirer => job.isPostedBy(userId),
      };
      if (!aboutMe) continue;

      yield AppNotification(
        id: 'rating-${rating.id}',
        kind: NotificationKind.ratingReceived,
        at: rating.createdAt,
        jobId: job.id,
        stars: rating.stars,
      );
    }
  }

  Iterable<AppNotification> _aboutWallet(
    Wallet wallet, {
    required bool locked,
    required DateTime now,
  }) sync* {
    for (final entry in wallet.entries) {
      switch (entry.kind) {
        case WalletEntryKind.commission:
          yield AppNotification(
            id: 'wallet-${entry.id}',
            kind: NotificationKind.commissionCharged,
            at: entry.createdAt,
            jobId: entry.jobId,
            // Stored as a negative movement; shown as an amount charged.
            amount: entry.tokens.abs(),
          );
        case WalletEntryKind.topUp ||
            WalletEntryKind.firstJobCredit ||
            WalletEntryKind.loyaltyBonus:
          yield AppNotification(
            id: 'wallet-${entry.id}',
            kind: NotificationKind.walletCredited,
            at: entry.createdAt,
            amount: entry.tokens.abs(),
          );
        // A penalty and an admin adjustment both reach the ledger, which the
        // wallet screen shows in full. Repeating them here as cheerful "your
        // wallet changed" lines would be worse than saying nothing.
        case WalletEntryKind.cancellationPenalty ||
            WalletEntryKind.adminAdjustment:
          break;
      }
    }

    // Not tied to an entry: this is a *state*, and the thing worth saying is
    // that bidding is closed right now. Dated to the newest entry, because
    // that is what put them here.
    if (locked && wallet.entries.isNotEmpty) {
      final latest = wallet.entries
          .map((e) => e.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      yield AppNotification(
        id: 'wallet-locked',
        kind: NotificationKind.walletLocked,
        at: latest,
      );
    }
  }

  Iterable<AppNotification> _aboutListing(
    DirectoryListing listing, {
    required DateTime now,
  }) sync* {
    final subscription = listing.subscription;
    if (subscription == null) return;

    if (subscription.isActiveAt(now)) {
      final left = subscription.expiresAt.difference(now);
      if (left <= subscriptionWarning) {
        yield AppNotification(
          // Dated to the day it enters the window rather than to "now", so it
          // does not jump to the top of the feed on every rebuild.
          id: 'subscription-expiring',
          kind: NotificationKind.subscriptionExpiring,
          at: subscription.expiresAt.subtract(subscriptionWarning),
        );
      }
      return;
    }

    yield AppNotification(
      id: 'subscription-lapsed',
      kind: NotificationKind.subscriptionLapsed,
      at: subscription.expiresAt,
    );
  }

  Iterable<AppNotification> _aboutVerification(AccountReview review) sync* {
    // Only a decision. "We are looking at it" is not news, and the
    // verification screen already says so in a place somebody chose to visit.
    final decidedAt = review.decidedAt;
    if (decidedAt == null) return;

    switch (review.status) {
      case ReviewStatus.approved:
        yield AppNotification(
          id: 'verification-decision',
          kind: NotificationKind.verificationApproved,
          at: decidedAt,
        );
      case ReviewStatus.suspended:
        yield AppNotification(
          id: 'verification-decision',
          kind: NotificationKind.verificationRejected,
          at: decidedAt,
        );
      case ReviewStatus.pending:
        break;
    }
  }
}
