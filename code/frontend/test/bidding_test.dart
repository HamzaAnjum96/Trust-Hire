import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:trust_hire/app/job_controller.dart';
import 'package:trust_hire/app/profile_controller.dart';
import 'package:trust_hire/app/wallet_controller.dart';
import 'package:trust_hire/features/jobs/job_details_sheet.dart';
import 'package:trust_hire/features/jobs/saved_jobs_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/bid_controller.dart';
import 'package:trust_hire/features/bidding/bidding_rules.dart';
import 'package:trust_hire/models/bid.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_status.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/models/worker_profile.dart';
import 'package:trust_hire/services/bid_repository.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';

import 'support/harness.dart';
import 'package:trust_hire/services/media_store.dart';
import 'package:trust_hire/models/account.dart';

/// Section 4: the hirer posts a starting fare, workers counter, the hirer
/// chooses, and the fare is locked at that moment.
///
/// The locking is the part worth testing hardest. Section 11 makes the whole
/// commission model depend on it — the number is trustworthy *because* it was
/// fixed before the work started — so a second write to it is not a cosmetic
/// bug, it is the platform charging against a figure nobody agreed to.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  const rules = BiddingRules();
  final now = DateTime(2026, 7, 27, 10);
  const islamabad = JobLocation(latitude: 33.7104, longitude: 73.0551);
  const muzaffarabad = JobLocation(latitude: 34.3700, longitude: 73.4711);

  Job job({
    Set<JobTag> tags = const {JobTag.misc},
    JobLocation location = islamabad,
    int? startingFare = 2000,
    bool isLocal = false,
    String? postedBy,
  }) => Job(
    id: 'job-1',
    location: location,
    createdAt: now,
    tags: tags,
    startingFare: startingFare,
    isLocal: isLocal,
    postedBy: postedBy,
  );

  Bid bid(String id, int fare, {int minutesAgo = 0, String worker = 'w'}) =>
      Bid(
        id: id,
        jobId: 'job-1',
        workerId: worker,
        fare: fare,
        createdAt: now.subtract(Duration(minutes: minutesAgo)),
      );

  WorkerProfile worker({Set<JobTag>? tags}) =>
      WorkerProfile(userId: 'w1', tags: tags);

  group('who may bid', () {
    test('a worker the job reaches may bid', () {
      expect(
        rules.canBid(
          job(),
          worker: worker(),
          from: islamabad,
          existingBids: const [],
        ),
        isTrue,
      );
    });

    test('a job outside the feed cannot be bid on', () {
      // The point of Section 8: not "shown but should not be bid on".
      expect(
        rules.refusalFor(
          job(tags: {JobTag.legal}),
          worker: worker(),
          from: islamabad,
          existingBids: const [],
        ),
        BidRefusal.notVisible,
      );
      expect(
        rules.refusalFor(
          job(location: muzaffarabad),
          worker: worker(),
          from: islamabad,
          existingBids: const [],
        ),
        BidRefusal.notVisible,
      );
    });

    test('a hirer cannot bid on their own job', () {
      expect(
        rules.refusalFor(
          job(postedBy: 'w1'),
          worker: worker(),
          from: islamabad,
          existingBids: const [],
        ),
        BidRefusal.ownJob,
      );
    });

    test('someone else may bid on it', () {
      // The mirror of the test above, and the reason demo accounts exist: the
      // same job is your own posting or somebody else's work depending only
      // on who you are currently being.
      expect(
        rules.refusalFor(
          job(postedBy: 'someone-else'),
          worker: worker(),
          from: islamabad,
          existingBids: const [],
        ),
        isNull,
      );
    });

    test('a job posted before demo accounts still belongs to the device', () {
      // Jobs already in local storage carry `isLocal` and no poster. Without
      // the fallback in Job.isPostedBy they would belong to nobody, and their
      // author could bid on their own work.
      expect(
        rules.refusalFor(
          job(isLocal: true),
          worker: WorkerProfile(userId: DemoAccounts.deviceId),
          from: islamabad,
          existingBids: const [],
        ),
        BidRefusal.ownJob,
      );
    });

    test('bidding closes once someone is chosen', () {
      expect(
        rules.refusalFor(
          job(),
          worker: worker(),
          from: islamabad,
          existingBids: [bid('a', 1800).copyWith(status: BidStatus.accepted)],
        ),
        BidRefusal.alreadyAccepted,
      );
    });
  });

  group('what counts as a fare', () {
    test('zero and below are refused', () {
      expect(rules.refusalForFare(0), BidRefusal.fareNotPositive);
      expect(rules.refusalForFare(-500), BidRefusal.fareNotPositive);
    });

    test('a plausible counter-offer is fine, high or low', () {
      // Section 4 sets no ceiling and no floor relative to the starting fare —
      // a worker may ask for more than was offered, and often should.
      expect(rules.refusalForFare(500, startingFare: 2000), isNull);
      expect(rules.refusalForFare(2000, startingFare: 2000), isNull);
      expect(rules.refusalForFare(8000, startingFare: 2000), isNull);
    });

    test('a mistyped extra zero is caught', () {
      // Not a rule from the spec: a Rs. 2,000 job carrying a Rs. 200,000 bid
      // is a typo, and the hirer should not have to catch it for them.
      expect(
        rules.refusalForFare(200000, startingFare: 2000),
        BidRefusal.fareImplausible,
      );
    });

    test('a job with no starting fare still has a sanity ceiling', () {
      expect(rules.refusalForFare(50000, startingFare: null), isNull);
      expect(
        rules.refusalForFare(5000000, startingFare: null),
        BidRefusal.fareImplausible,
      );
    });
  });

  group('the order the hirer reads them in', () {
    test('cheapest first, ties broken by who offered first', () {
      final ordered = rules.forReview([
        bid('c', 3000),
        bid('a', 1500, minutesAgo: 5),
        bid('b', 1500, minutesAgo: 30),
        bid('d', 2000),
      ]);

      expect(ordered.map((b) => b.id), ['b', 'a', 'd', 'c']);
    });

    test('a withdrawn offer leaves the list', () {
      final ordered = rules.forReview([
        bid('a', 1500).copyWith(status: BidStatus.withdrawn),
        bid('b', 3000),
      ]);

      expect(ordered.map((b) => b.id), ['b']);
    });

    test('ordering is not a recommendation', () {
      // Section 4 forbids auto-selection. Nothing about the order marks a bid
      // as chosen, and reading order must not become one.
      final ordered = rules.forReview([bid('a', 1500), bid('b', 3000)]);
      expect(ordered.every((b) => b.status == BidStatus.offered), isTrue);
    });
  });

  group('choosing', () {
    test('one accepted, everyone else passed over', () {
      final all = [bid('a', 1500), bid('b', 2000), bid('c', 2500)];
      final after = rules.accept(all[1], allBidsOnJob: all);

      expect(after.singleWhere((b) => b.id == 'b').status, BidStatus.accepted);
      expect(
        after.where((b) => b.status == BidStatus.passedOver).map((b) => b.id),
        ['a', 'c'],
      );
      expect(after.where((b) => b.status == BidStatus.accepted), hasLength(1));
    });

    test('a withdrawn offer is left alone', () {
      // It was already gone; marking it "not chosen" would tell the worker
      // they lost something they had taken back.
      final all = [
        bid('a', 1500).copyWith(status: BidStatus.withdrawn),
        bid('b', 2000),
      ];
      final after = rules.accept(all[1], allBidsOnJob: all);

      expect(after.singleWhere((b) => b.id == 'a').status, BidStatus.withdrawn);
    });
  });

  group('the fare is locked at acceptance', () {
    test('accepting sets the agreed fare and the worker', () {
      final accepted = job().withAcceptedBid(workerId: 'w9', fare: 1800);

      expect(accepted.agreedFare, 1800);
      expect(accepted.acceptedWorkerId, 'w9');
      expect(accepted.isAccepted, isTrue);
      // The opening number survives, so the hirer can see what they asked for.
      expect(accepted.startingFare, 2000);
    });

    test('a second acceptance changes nothing', () {
      // The whole basis of Section 11: the commission is trustworthy because
      // the figure it is taken from was fixed before the work started.
      final accepted = job().withAcceptedBid(workerId: 'w9', fare: 1800);
      final again = accepted.withAcceptedBid(workerId: 'w2', fare: 400);

      expect(again.agreedFare, 1800);
      expect(again.acceptedWorkerId, 'w9');
    });

    test('editing the job cannot touch it', () {
      final accepted = job().withAcceptedBid(workerId: 'w9', fare: 1800);
      final edited = accepted.copyWith(
        title: 'Changed my mind',
        startingFare: 99,
      );

      expect(edited.agreedFare, 1800);
      expect(edited.acceptedWorkerId, 'w9');
      expect(edited.startingFare, 99, reason: 'the opening ask is still hers');
    });

    test('it survives storage', () {
      final accepted = job().withAcceptedBid(workerId: 'w9', fare: 1800);
      final restored = Job.fromJson(accepted.toJson());

      expect(restored.agreedFare, 1800);
      expect(restored.acceptedWorkerId, 'w9');
      expect(restored.startingFare, 2000);
    });

    test('a job saved before bidding existed has no fares', () {
      final legacy = job(startingFare: null).toJson()
        ..remove('startingFare')
        ..remove('agreedFare')
        ..remove('acceptedWorkerId');

      final restored = Job.fromJson(legacy);
      expect(restored.startingFare, isNull);
      expect(restored.isAccepted, isFalse);
    });
  });

  group('the hirer\'s side of the sheet', () {
    testWidgets('a job with no offers says so, and offers nothing to choose', (
      tester,
    ) async {
      final harness = await _harness(tester, jobs: [job(isLocal: true)]);
      await harness.settle();
      await harness.revealOffers();

      expect(find.text('Offers'), findsOneWidget);
      expect(find.textContaining('Nobody has offered yet'), findsOneWidget);
      expect(find.text('Choose'), findsNothing);
    });

    testWidgets('choosing locks the fare and closes bidding', (tester) async {
      final posted = job(isLocal: true);
      final harness = await _harness(tester, jobs: [posted]);
      await harness.bids.placeBid(jobId: posted.id, fare: 1800);
      await harness.settle();

      await harness.revealOffers();
      expect(find.text('Rs. 1,800'), findsWidgets);

      await tester.tap(find.text('Choose').first);
      await harness.settle();
      // The warning is repeated in the dialog, deliberately: it is the last
      // moment the hirer can change their mind.
      expect(find.textContaining('cannot be changed'), findsWidgets);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Choose'),
        ),
      );
      await harness.settle();

      expect(harness.jobs.jobById(posted.id)!.agreedFare, 1800);
      expect(harness.bids.myBidOn(posted.id)!.status, BidStatus.accepted);
      // No second choice is on offer once one is made.
      expect(find.text('Choose'), findsNothing);
      // skipOffstage: the sheet is a ListView and the offers can sit outside
      // the built range once the dialog has closed and it has re-laid out.
      expect(find.text('Chosen', skipOffstage: false), findsOneWidget);
    });
  });

  group('the seed data', () {
    test('most jobs open with a fare, and some deliberately do not', () async {
      // A hirer who has no idea what the work is worth must still be able to
      // post, so the demo has to look right when they have not said.
      final store = await LocalStore.open();
      final repository = JobRepository(store, MediaStore(store));
      await repository.ensureSeeded();
      final jobs = await repository.fetchJobs();

      expect(jobs.where((j) => j.startingFare != null), isNotEmpty);
      expect(jobs.where((j) => j.startingFare == null), isNotEmpty);
      for (final j in jobs.where((j) => j.startingFare != null)) {
        expect(j.startingFare, greaterThan(0), reason: j.id);
      }
    });

    test('a job that was accepted agrees with the bid behind it', () async {
      // The seed gives the demo a past — offers, choices and finished work —
      // and the fare is where that could quietly go wrong. Section 4 makes
      // acceptance the thing that fixes the price, so a seeded job whose
      // agreed fare disagreed with its accepted bid would be a demonstration
      // of a bug rather than of the rule.
      final store = await LocalStore.open();
      final repository = JobRepository(store, MediaStore(store));
      await repository.ensureSeeded();

      final jobs = await repository.fetchJobs();
      final bids = await BidRepository(store).fetchBids();

      final accepted = jobs.where((job) => job.isAccepted).toList();
      expect(accepted, isNotEmpty, reason: 'the demo needs finished work');

      for (final job in accepted) {
        final winner = bids.singleWhere(
          (bid) => bid.jobId == job.id && bid.status == BidStatus.accepted,
          orElse: () => throw StateError('${job.id} has no accepted bid'),
        );

        expect(job.agreedFare, winner.fare, reason: job.id);
        expect(job.acceptedWorkerId, winner.workerId, reason: job.id);
      }
    });

    test('an open job has nobody on it, and nobody accepted', () async {
      final store = await LocalStore.open();
      final repository = JobRepository(store, MediaStore(store));
      await repository.ensureSeeded();

      final jobs = await repository.fetchJobs();
      final bids = await BidRepository(store).fetchBids();
      final open = jobs.where((job) => job.status == JobStatus.open);

      expect(open, isNotEmpty, reason: 'the map needs work to offer on');

      for (final job in open) {
        expect(job.acceptedWorkerId, isNull, reason: job.id);
        expect(job.agreedFare, isNull, reason: job.id);
        expect(
          bids.where(
            (bid) => bid.jobId == job.id && bid.status == BidStatus.accepted,
          ),
          isEmpty,
          reason: job.id,
        );
      }
    });

    test('somebody has been passed over', () async {
      // The state a worker sees most often, and the one that existed only in
      // the tests until the seed grew a history.
      final store = await LocalStore.open();
      await JobRepository(store, MediaStore(store)).ensureSeeded();

      final bids = await BidRepository(store).fetchBids();
      expect(
        bids.where((bid) => bid.status == BidStatus.passedOver),
        isNotEmpty,
      );
    });
  });

  group('posted to accepted, end to end', () {
    Future<BidController> controller() async {
      final store = await LocalStore.open();
      return BidController(BidRepository(store))..load();
    }

    test('a worker offers, the hirer chooses, the fare is locked', () async {
      final bids = await controller();
      final posted = job();

      await bids.placeBid(jobId: posted.id, fare: 1800, message: 'Can do it');
      final mine = bids.myBidOn(posted.id);

      expect(mine, isNotNull);
      expect(mine!.fare, 1800);
      expect(mine.message, 'Can do it');

      final accepted = await bids.accept(mine, job: posted);

      expect(accepted.agreedFare, 1800);
      expect(accepted.acceptedWorkerId, DemoAccounts.deviceId);
      expect(bids.myBidOn(posted.id)!.status, BidStatus.accepted);
    });

    test('bids survive a restart', () async {
      final store = await LocalStore.open();
      await (BidController(
        BidRepository(store),
      )..load()).placeBid(jobId: 'job-1', fare: 1800);

      final reloaded = BidController(BidRepository(store));
      await reloaded.load();

      expect(reloaded.myBidOn('job-1')?.fare, 1800);
    });

    test('changing an offer replaces it rather than adding a second', () async {
      // Two live bids from one worker would let them occupy a hirer's list
      // twice, and there is no honest way to show that.
      final bids = await controller();

      await bids.placeBid(jobId: 'job-1', fare: 1800);
      await bids.placeBid(jobId: 'job-1', fare: 1600);

      expect(bids.forJob('job-1'), hasLength(1));
      expect(bids.myBidOn('job-1')!.fare, 1600);
    });

    test('an empty message is stored as absent, not as blank', () async {
      final bids = await controller();

      await bids.placeBid(jobId: 'job-1', fare: 1800, message: '   ');
      expect(bids.myBidOn('job-1')!.message, isNull);
    });

    test('withdrawing takes the offer off the hirer\'s list', () async {
      final bids = await controller();
      await bids.placeBid(jobId: 'job-1', fare: 1800);

      await bids.withdrawBid('job-1');

      expect(bids.myBidOn('job-1')!.status, BidStatus.withdrawn);
      expect(bids.forReview('job-1'), isEmpty);
    });

    test('an accepted offer cannot be withdrawn or revised', () async {
      final bids = await controller();
      await bids.placeBid(jobId: 'job-1', fare: 1800);
      await bids.accept(bids.myBidOn('job-1')!, job: job());

      await bids.withdrawBid('job-1');
      expect(bids.myBidOn('job-1')!.status, BidStatus.accepted);

      expect(await bids.placeBid(jobId: 'job-1', fare: 100), isNull);
      expect(bids.myBidOn('job-1')!.fare, 1800);
    });

    test('accepting twice cannot double-book the job', () async {
      final bids = await controller();
      await bids.placeBid(jobId: 'job-1', fare: 1800);

      final first = await bids.accept(bids.myBidOn('job-1')!, job: job());
      final second = await bids.accept(bids.myBidOn('job-1')!, job: first);

      expect(second.agreedFare, 1800);
      expect(
        bids.forJob('job-1').where((b) => b.status == BidStatus.accepted),
        hasLength(1),
      );
    });

    test('deleting a job takes its bids with it', () async {
      final bids = await controller();
      await bids.placeBid(jobId: 'job-1', fare: 1800);
      await bids.placeBid(jobId: 'job-2', fare: 900);

      await bids.forgetJob('job-1');

      expect(bids.forJob('job-1'), isEmpty);
      expect(bids.forJob('job-2'), hasLength(1));
    });
  });
}

/// A details sheet with the controllers it needs, for the two widget tests
/// above. Kept out of the main body so the rule tests stay readable.
class _Harness {
  _Harness(this.tester, this.jobs, this.bids);

  final WidgetTester tester;
  final JobController jobs;
  final BidController bids;

  Future<void> settle() async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Drags the sheet up so the offers build.
  ///
  /// A drag rather than `ensureVisible` or `scrollUntilVisible`: the sheet is
  /// a ListView, so anything below the fold does not exist yet, and both of
  /// those need the widget to be in the tree already. P1-3 put the job's
  /// status above the offers, which pushed them out of the built range.
  Future<void> revealOffers() async {
    for (var attempt = 0; attempt < 4; attempt++) {
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await settle();
    }
  }
}

Future<_Harness> _harness(
  WidgetTester tester, {
  required List<Job> jobs,
}) async {
  final store = await LocalStore.open();
  final media = MediaStore(store);
  final jobController = JobController(JobRepository(store, media));

  for (final job in jobs) {
    await jobController.saveJob(job);
  }
  await jobController.load();

  final bidController = BidController(BidRepository(store))..load();
  final profile = ProfileController(store)..load();
  final wallet = WalletController(store)..load();
  final saved = SavedJobsController(store)..load();

  await tester.pumpWidget(
    appHarness(
      store: store,
      media: media,
      jobs: jobController,
      bids: bidController,
      profile: profile,
      wallet: wallet,
      saved: saved,
      child: Scaffold(
        body: JobDetailsSheet(jobId: jobs.first.id, mediaStore: media),
      ),
    ),
  );

  return _Harness(tester, jobController, bidController);
}
