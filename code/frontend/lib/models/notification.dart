/// What happened, from the point of view of one person.
///
/// **Derived, never stored.** Every entry here is computed from the jobs, bids,
/// ratings and ledger already on the device — see `NotificationRules`. The
/// obvious alternative is an event table written by each controller as things
/// happen, and it was rejected for the reason this codebase keeps running into:
/// a write that somebody forgets to make is invisible, and the test for the
/// feature passes anyway because it seeds the table directly. A derived feed
/// cannot drift from the data, because it *is* the data.
///
/// The cost is that individual entries cannot be marked read — only "seen up to
/// here", which is what `NotificationController` stores. That is a real
/// limitation and an honest one; plenty of shipped apps work exactly this way.
library;

enum NotificationKind {
  /// Somebody made an offer on a job you posted.
  offerReceived,

  /// Your offer was chosen. The one that matters most on this list.
  offerAccepted,

  /// Somebody else's offer was chosen. Said plainly, because a worker
  /// refreshing a job to find out is worse than being told.
  offerPassedOver,

  /// The worker has arrived and the job is under way.
  jobStarted,

  /// The job is finished — which is also when rating opens and commission is
  /// charged, so it is the busiest moment in the app.
  jobCompleted,

  /// Called off. Reaches the other side, whoever did it.
  jobCancelled,

  /// The job's time came and went with nobody on it.
  jobExpired,

  /// Somebody rated you.
  ratingReceived,

  /// The platform took its 5%.
  commissionCharged,

  /// A top-up, a first-job credit, a loyalty bonus, or an admin's correction.
  walletCredited,

  /// Two unpaid jobs. Bidding is closed until the balance is settled, and a
  /// worker who does not know that will read the refusal as a bug.
  walletLocked,

  /// A directory subscription with under a fortnight left.
  subscriptionExpiring,

  /// A directory subscription that has run out. The listing stops being found.
  subscriptionLapsed,

  /// An admin approved the account.
  verificationApproved,

  /// An admin rejected it, or flagged it for a name mismatch.
  verificationRejected,
}

/// One line in the feed.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.at,
    this.jobId,
    this.otherPartyId,
    this.amount,
    this.stars,
  });

  /// Stable across rebuilds, because it is derived from the record it came
  /// from rather than counted. An id that changed every time the list was
  /// rebuilt would make "seen" meaningless and the list animate on every
  /// keystroke elsewhere in the app.
  final String id;

  final NotificationKind kind;

  /// When the underlying thing happened — not when it was noticed.
  final DateTime at;

  /// The job this is about, where there is one. Tapping the entry opens it.
  final String? jobId;

  /// The other person: the worker who offered, the hirer who booked, whoever
  /// left the rating.
  final String? otherPartyId;

  /// Rupees, for the money entries.
  final int? amount;

  /// Stars, for a rating.
  final int? stars;

  /// Whether tapping this should go anywhere.
  bool get opensJob => jobId != null;

  /// The ones worth interrupting somebody for, if this app ever gets push
  /// notifications. Kept here rather than on the screen so that the answer is
  /// the same wherever it is asked.
  bool get isHighPriority => switch (kind) {
    NotificationKind.offerAccepted ||
    NotificationKind.offerPassedOver ||
    NotificationKind.jobCancelled ||
    NotificationKind.walletLocked ||
    NotificationKind.verificationApproved ||
    NotificationKind.verificationRejected => true,
    _ => false,
  };
}
