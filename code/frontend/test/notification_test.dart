import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trust_hire/app/notification_controller.dart';
import 'package:trust_hire/features/notifications/notification_rules.dart';
import 'package:trust_hire/models/admin.dart';
import 'package:trust_hire/models/bid.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_status.dart';
import 'package:trust_hire/models/notification.dart';
import 'package:trust_hire/models/premium.dart';
import 'package:trust_hire/models/rating.dart';
import 'package:trust_hire/models/verification.dart';
import 'package:trust_hire/models/wallet.dart';
import 'package:trust_hire/services/local_store.dart';

/// The notification feed.
///
/// **Two things here are load-bearing, and neither is the wording.**
///
/// The first is that the feed reaches the right person and nobody else. It is
/// assembled from every job, bid and rating on the device, because that is what
/// a local-first app has — so the filtering *is* the privacy boundary. Get it
/// wrong and Trust Hire ships a public activity log of the whole marketplace.
///
/// The second is that a worker is told when they lose. That is the entry a
/// product is tempted to leave out, and leaving it out means a worker refreshes
/// a job for three days to find out by omission.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  const rules = NotificationRules();
  final now = DateTime(2026, 8, 4, 12);
  DateTime ago(int days) => now.subtract(Duration(days: days));

  Job job(
    String id, {
    String hirer = 'hina',
    String? worker,
    JobStatus status = JobStatus.open,
    int? fare,
    DateTime? changedAt,
  }) => Job(
    id: id,
    location: const JobLocation(latitude: 31.5, longitude: 74.3),
    createdAt: ago(10),
    title: 'Job $id',
    postedBy: hirer,
    acceptedWorkerId: worker,
    agreedFare: fare,
    status: status,
    statusChangedAt: changedAt,
  );

  Bid bid(
    String id, {
    required String jobId,
    String workerId = 'usman',
    int fare = 2000,
    BidStatus status = BidStatus.offered,
    DateTime? at,
  }) => Bid(
    id: id,
    jobId: jobId,
    workerId: workerId,
    fare: fare,
    status: status,
    createdAt: at ?? ago(5),
  );

  List<AppNotification> feedFor(
    String user, {
    List<Job> jobs = const [],
    List<Bid> bids = const [],
    List<Rating> ratings = const [],
    Wallet? wallet,
    DirectoryListing? listing,
    AccountReview? review,
    bool walletLocked = false,
  }) => rules.forUser(
    user,
    jobs: jobs,
    bids: bids,
    ratings: ratings,
    wallet: wallet,
    listing: listing,
    review: review,
    walletLocked: walletLocked,
    now: now,
  );

  Set<NotificationKind> kindsFor(String user, {
    List<Job> jobs = const [],
    List<Bid> bids = const [],
    List<Rating> ratings = const [],
  }) => feedFor(user, jobs: jobs, bids: bids, ratings: ratings)
      .map((e) => e.kind)
      .toSet();

  group('who hears about a job', () {
    final theJob = job(
      'j1',
      worker: 'usman',
      status: JobStatus.completed,
      fare: 3000,
      changedAt: ago(1),
    );
    final offers = [
      bid('b1', jobId: 'j1', workerId: 'usman', status: BidStatus.accepted),
      bid('b2', jobId: 'j1', workerId: 'bilal', status: BidStatus.passedOver),
    ];

    test('the hirer and the worker, and nobody else', () {
      // **The privacy boundary.** The feed is built from every job and bid on
      // the device, because that is all a local-first app has. If this filter
      // is wrong, the app is a public activity log of the whole marketplace.
      expect(
        kindsFor('stranger', jobs: [theJob], bids: offers),
        isEmpty,
        reason: 'somebody with no part in this job heard about it',
      );

      expect(kindsFor('hina', jobs: [theJob], bids: offers), isNotEmpty);
      expect(kindsFor('usman', jobs: [theJob], bids: offers), isNotEmpty);
    });

    test('a hirer hears about every offer that came in', () {
      final received = feedFor(
        'hina',
        jobs: [job('j1')],
        bids: [
          bid('b1', jobId: 'j1', workerId: 'usman'),
          bid('b2', jobId: 'j1', workerId: 'bilal'),
        ],
      ).where((e) => e.kind == NotificationKind.offerReceived);

      expect(received, hasLength(2));
      expect(
        received.first.amount,
        2000,
        reason: 'the number is the point — "somebody offered" is not news',
      );
    });

    test('but not about their own offer on somebody else\'s job', () {
      // Hina bidding on her own job is refused elsewhere; this is the case
      // where she is the worker on a job she did not post.
      expect(
        kindsFor(
          'usman',
          jobs: [job('j1', hirer: 'hina')],
          bids: [bid('b1', jobId: 'j1', workerId: 'usman')],
        ),
        isEmpty,
        reason: 'making an offer is not news to the person who made it',
      );
    });

    test('a withdrawn offer is not reported as having arrived', () {
      expect(
        kindsFor(
          'hina',
          jobs: [job('j1')],
          bids: [bid('b1', jobId: 'j1', status: BidStatus.withdrawn)],
        ),
        isEmpty,
      );
    });
  });

  group('a worker is told what happened to their offer', () {
    test('when it wins, with the fare', () {
      final won = feedFor(
        'usman',
        jobs: [
          job(
            'j1',
            worker: 'usman',
            status: JobStatus.accepted,
            changedAt: ago(2),
          ),
        ],
        bids: [
          bid(
            'b1',
            jobId: 'j1',
            workerId: 'usman',
            fare: 2500,
            status: BidStatus.accepted,
            at: ago(9),
          ),
        ],
      ).single;

      expect(won.kind, NotificationKind.offerAccepted);
      expect(won.amount, 2500);
      expect(
        won.at,
        ago(2),
        reason: 'dated to when the offer was taken, not when it was made — '
            'the bid was a week older than the decision',
      );
    });

    test('and when it loses', () {
      // **The entry a product leaves out.** Without it a worker refreshes a
      // job for three days and finds out by omission.
      expect(
        kindsFor(
          'bilal',
          jobs: [job('j1', worker: 'usman', status: JobStatus.accepted)],
          bids: [
            bid('b1', jobId: 'j1', workerId: 'bilal', status: BidStatus.passedOver),
          ],
        ),
        contains(NotificationKind.offerPassedOver),
      );
    });

    test('an offer still standing is not an update', () {
      expect(
        kindsFor(
          'usman',
          jobs: [job('j1')],
          bids: [bid('b1', jobId: 'j1', workerId: 'usman')],
        ),
        isEmpty,
      );
    });
  });

  group('ratings', () {
    Rating rating(String id, RatedSide side, {int stars = 5}) => Rating(
      id: id,
      jobId: 'j1',
      side: side,
      stars: stars,
      createdAt: ago(1),
    );

    final finished = job(
      'j1',
      hirer: 'hina',
      worker: 'usman',
      status: JobStatus.completed,
      changedAt: ago(2),
    );

    test('reach the person who was rated, not the one who wrote it', () {
      final forWorker = feedFor(
        'usman',
        jobs: [finished],
        ratings: [rating('r1', RatedSide.worker, stars: 4)],
      ).where((e) => e.kind == NotificationKind.ratingReceived);

      expect(forWorker, hasLength(1));
      expect(forWorker.single.stars, 4);

      expect(
        feedFor(
          'hina',
          jobs: [finished],
          ratings: [rating('r1', RatedSide.worker)],
        ).where((e) => e.kind == NotificationKind.ratingReceived),
        isEmpty,
        reason: 'the hirer wrote that one; being told about it is odd',
      );
    });
  });

  group('the wallet', () {
    Wallet walletWith(List<WalletEntry> entries) =>
        Wallet(userId: 'usman', entries: entries);

    WalletEntry entry(
      String id,
      WalletEntryKind kind,
      int tokens, {
      int daysAgo = 3,
    }) => WalletEntry(
      id: id,
      kind: kind,
      tokens: tokens,
      createdAt: ago(daysAgo),
    );

    test('a commission is reported as an amount charged, not as a negative', () {
      final charged = feedFor(
        'usman',
        wallet: walletWith([entry('w1', WalletEntryKind.commission, -150)]),
      ).single;

      expect(charged.kind, NotificationKind.commissionCharged);
      expect(charged.amount, 150, reason: 'shown as charged, not as -150');
    });

    test('the lockout is said out loud', () {
      // A worker who does not know bidding is closed reads the refusal on the
      // offer screen as a bug in the app.
      expect(
        feedFor(
          'usman',
          wallet: walletWith([entry('w1', WalletEntryKind.commission, -150)]),
          walletLocked: true,
        ).map((e) => e.kind),
        contains(NotificationKind.walletLocked),
      );
    });

    test('a penalty and an admin correction stay in the ledger', () {
      // Both are visible on the wallet screen in full. Repeating them here as
      // cheerful "your wallet changed" lines would be worse than silence.
      expect(
        feedFor(
          'usman',
          wallet: walletWith([
            entry('w1', WalletEntryKind.cancellationPenalty, -500),
            entry('w2', WalletEntryKind.adminAdjustment, 500),
          ]),
        ),
        isEmpty,
      );
    });
  });

  group('the directory subscription', () {
    DirectoryListing listing({required int endsInDays}) => DirectoryListing(
      workerId: 'usman',
      subscription: Subscription(
        plan: SubscriptionPlan.monthly,
        startedAt: ago(60),
        expiresAt: now.add(Duration(days: endsInDays)),
      ),
    );

    test('says nothing while there is plenty of time left', () {
      expect(feedFor('usman', listing: listing(endsInDays: 90)), isEmpty);
    });

    test('warns inside the last fortnight', () {
      expect(
        feedFor('usman', listing: listing(endsInDays: 5)).single.kind,
        NotificationKind.subscriptionExpiring,
      );
    });

    test('and says plainly when the listing has stopped being found', () {
      expect(
        feedFor('usman', listing: listing(endsInDays: -3)).single.kind,
        NotificationKind.subscriptionLapsed,
      );
    });
  });

  group('verification', () {
    AccountReview review(ReviewStatus status, {DateTime? decidedAt}) =>
        AccountReview(
          userId: 'usman',
          status: status,
          verification: const Verification(),
          decidedAt: decidedAt,
        );

    test('a decision is news; being in a queue is not', () {
      expect(
        feedFor('usman', review: review(ReviewStatus.pending)),
        isEmpty,
        reason: '"we are looking at it" is not an update',
      );

      expect(
        feedFor(
          'usman',
          review: review(ReviewStatus.approved, decidedAt: ago(1)),
        ).single.kind,
        NotificationKind.verificationApproved,
      );
    });

    test('an approval with no date on it is not shown', () {
      // Rather than dating it "now" and floating to the top of the feed on
      // every rebuild.
      expect(feedFor('usman', review: review(ReviewStatus.approved)), isEmpty);
    });
  });

  group('the shape of the feed', () {
    test('is newest first', () {
      final feed = feedFor(
        'hina',
        jobs: [job('j1'), job('j2')],
        bids: [
          bid('old', jobId: 'j1', workerId: 'a', at: ago(9)),
          bid('new', jobId: 'j2', workerId: 'b', at: ago(1)),
          bid('mid', jobId: 'j1', workerId: 'c', at: ago(4)),
        ],
      );

      expect(
        feed.map((e) => e.at),
        [ago(1), ago(4), ago(9)],
      );
    });

    test('holds nothing dated in the future', () {
      // The seed works in offsets from whenever it is read. A job scheduled
      // for tomorrow must not appear as something that already happened.
      final ahead = feedFor(
        'hina',
        jobs: [job('j1')],
        bids: [
          bid('later', jobId: 'j1', workerId: 'a', at: now.add(
            const Duration(days: 2),
          )),
        ],
      );

      expect(ahead, isEmpty);
    });

    test('ids are stable across rebuilds', () {
      // The "seen" mark and the highlighting both key off these. Ids that
      // changed per build would make both meaningless.
      List<String> ids() => feedFor(
        'hina',
        jobs: [job('j1')],
        bids: [bid('b1', jobId: 'j1', workerId: 'a')],
      ).map((e) => e.id).toList();

      expect(ids(), ids());
    });
  });

  group('what counts as unseen', () {
    final feed = [
      AppNotification(
        id: 'a',
        kind: NotificationKind.offerReceived,
        at: ago(1),
      ),
      AppNotification(
        id: 'b',
        kind: NotificationKind.offerReceived,
        at: ago(5),
      ),
    ];

    test('nothing, until an account has looked once', () {
      // Only reachable through the rules — the controller starts every
      // account's clock the moment it is switched to.
      // **A demo account carries two years of seeded history.** Counting all
      // of it as unread would open the app on a badge reading 47, none of
      // which happened while anybody was watching.
      expect(rules.unseen(feed, null), 0);
    });

    test('and after that, whatever arrived since', () {
      expect(rules.unseen(feed, ago(3)), 1);
      expect(rules.unseen(feed, ago(9)), 2);
      expect(rules.unseen(feed, now), 0);
    });
  });

  group('the seen mark', () {
    // Switching to an account for the first time starts its clock at the
    // present moment, and the mark only ever moves forward — so these work in
    // times *after* that rather than in the fixed `now` the rules use.
    DateTime later(int minutes) =>
        DateTime.now().add(Duration(minutes: minutes));

    test('is kept per account, not per device', () async {
      // Switching to Hina and back must not mark Usman's offers as read. The
      // whole point of the demo accounts is that they are separate people.
      final store = await LocalStore.open();
      final controller = NotificationController(store)..load();

      final mark = later(10);
      controller.setAccount('usman');
      await controller.markSeen(at: mark);

      controller.setAccount('hina');
      expect(
        controller.seenAt,
        isNot(mark),
        reason: "Hina inherited Usman's read state",
      );

      controller.setAccount('usman');
      expect(controller.seenAt, mark);
    });

    test('survives a restart', () async {
      final store = await LocalStore.open();
      final mark = later(10);
      final controller = NotificationController(store)..load();
      controller.setAccount('usman');
      await controller.markSeen(at: mark);

      final reopened = NotificationController(store)..load();
      reopened.setAccount('usman');

      expect(reopened.seenAt, mark);
    });

    test('only ever moves forward', () async {
      // Opening a tab rebuilds several times, and a stale timestamp arriving
      // late must not un-read what was already read.
      final store = await LocalStore.open();
      final controller = NotificationController(store)..load();
      controller.setAccount('usman');

      final forward = later(20);
      await controller.markSeen(at: forward);
      await controller.markSeen(at: later(5));

      expect(controller.seenAt, forward);
    });
  });
}
