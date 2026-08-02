import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trust_hire/app/account_controller.dart';
import 'package:trust_hire/app/admin_controller.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/bid_controller.dart';
import 'package:trust_hire/app/bootstrap.dart';
import 'package:trust_hire/app/job_controller.dart';
import 'package:trust_hire/app/premium_controller.dart';
import 'package:trust_hire/app/rating_controller.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/app/verification_controller.dart';
import 'package:trust_hire/app/wallet_controller.dart';
import 'package:trust_hire/features/wallet/wallet_rules.dart';
import 'package:trust_hire/models/account.dart';
import 'package:trust_hire/app/sync_controller.dart';
import 'package:trust_hire/models/bid.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/services/backend/mock_backend.dart';
import 'package:trust_hire/services/backend/remote_api.dart';
import 'package:trust_hire/services/seed_loader.dart';
import 'package:trust_hire/models/job_status.dart';
import 'package:trust_hire/services/bid_repository.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';

import 'support/surface.dart';

/// The demo, stop by stop.
///
/// [`documents/product/demo-script.md`](../../../documents/product/demo-script.md)
/// tells somebody how to see each Phase 1 rule working: which account to be,
/// which screen to open, and what should be on it. **A script nobody checks
/// rots**, and it rots silently — the reader finds out by following it in front
/// of an audience.
///
/// So every stop in that document has an assertion here. These do not test the
/// rules; every rule already has its own file. What they test is that the
/// demonstration is still *reachable*: that the account still has the data, the
/// screen still has the control, and the walkthrough still walks.
///
/// This is the phase-1 retro's fourth action in its sharpest form. The seed was
/// coherent for three sprints while the hirer's side of Mode A was unreachable
/// from four of the five accounts, and every coherence test passed throughout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  /// The map keeps tile requests in flight against a server the test cannot
  /// reach, so `pumpAndSettle` never returns. A fixed span is enough.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<LocalStore> ready() async {
    final store = await bootstrap();
    await (SettingsController(store)..load()).markIntroSeen();
    return store;
  }

  group('stop 1 — the app opens on work, with no account and no network', () {
    testWidgets('and the five destinations are all there', (tester) async {
      final store = await ready();
      await tester.useCompactSurface();
      await tester.pumpWidget(TrustHireApp(store: store));
      await settle(tester);

      // The bottom bar is the whole of the demo's navigation. If one of these
      // is missing, half the script cannot be followed.
      for (final destination in [
        'Map',
        'Jobs',
        'Directory',
        'Activity',
        'Profile',
      ]) {
        expect(
          find.text(destination),
          findsWidgets,
          reason: 'the script sends the reader to "$destination"',
        );
      }
    });

    testWidgets('the device account is clean, which is what a new user sees',
        (tester) async {
      final store = await ready();
      final account = AccountController(store)..load();

      expect(account.activeId, DemoAccounts.deviceId);

      final jobs = JobController(JobRepository(store, MediaStore(store)))
        ..load();
      await tester.pump();
      expect(
        jobs.jobs.where((job) => job.isPostedBy(DemoAccounts.deviceId)),
        isEmpty,
        reason: 'the device account is deliberately left with no history',
      );
    });
  });

  group('stop 2 — Hina Butt, the hirer', () {
    testWidgets('has postings, and at least one with offers to choose between',
        (tester) async {
      // The screen bidding exists for. This is the exact reachability the seed
      // lacked for three sprints while every coherence test passed.
      final store = await ready();
      const hina = 'user-003';

      final jobs = JobController(JobRepository(store, MediaStore(store)))
        ..load();
      final bids = BidController(BidRepository(store))..setAccount(hina);
      await bids.load();
      await tester.pump();

      final hers = jobs.jobs.where((job) => job.isPostedBy(hina)).toList();
      expect(hers, isNotEmpty, reason: 'Hina must have something posted');

      final withOffers = hers.where(
        (job) =>
            job.status == JobStatus.open &&
            bids.forJob(job.id).where((b) => b.status == BidStatus.offered)
                .isNotEmpty,
      );

      expect(
        withOffers,
        isNotEmpty,
        reason: 'the script says to open a posting and choose between offers',
      );
    });

    testWidgets('and one finished job she can be shown a rating on',
        (tester) async {
      final store = await ready();
      const hina = 'user-003';

      final jobs = JobController(JobRepository(store, MediaStore(store)))
        ..load();
      final ratings = RatingController(store)..load();
      await tester.pump();

      final finished = jobs.jobs.where(
        (job) => job.isPostedBy(hina) && job.status == JobStatus.completed,
      );

      expect(finished, isNotEmpty);
      expect(
        finished.any((job) => ratings.forJob(job.id).isNotEmpty),
        isTrue,
        reason: 'the script shows a finished job carrying its rating',
      );
    });
  });

  group('stop 3 — Bilal Awan, stopped by what he owes', () {
    testWidgets('is locked out, and the ledger says why', (tester) async {
      final store = await ready();
      const bilal = 'user-016';

      final wallet = WalletController(store)..setAccount(bilal);
      wallet.load();
      await tester.pump();

      expect(
        wallet.isLockedOut,
        isTrue,
        reason: 'the script uses Bilal to show the debt rule refusing work',
      );
      expect(wallet.balance, lessThan(0));

      // And it is two unpaid commissions rather than one big number, because
      // Section 11's rule is about jobs rather than about the balance.
      expect(const WalletRules().isLockedOut(wallet.wallet), isTrue);
    });
  });

  group('stop 4 — Shahid Siddiqui, nearly new', () {
    testWidgets('has the first-job credit still visible in his ledger',
        (tester) async {
      final store = await ready();
      const shahid = 'user-017';

      final wallet = WalletController(store)..setAccount(shahid);
      wallet.load();
      await tester.pump();

      expect(
        wallet.wallet.hasFirstJobCredit,
        isTrue,
        reason: 'the script uses Shahid to show the credit as its own entry',
      );
      expect(wallet.balance, greaterThan(0));
    });
  });

  group('stop 5 — the directory, and Mode B', () {
    testWidgets('has listings a hirer can book, at fixed prices',
        (tester) async {
      final store = await ready();
      final premium = PremiumController(store)..load();
      await tester.pump();

      final listings = premium.directory();
      expect(listings, isNotEmpty);

      expect(
        listings.any((listing) => listing.services.isNotEmpty),
        isTrue,
        reason: 'a directory with no service menus demonstrates nothing',
      );
    });

    testWidgets('and it leaves out the people who would not travel to you',
        (tester) async {
      // The script says the directory applies each worker's own radius. It is
      // seeded across the whole country, so standing in Karachi must exclude
      // somebody — otherwise the claim is true of an empty rule.
      final store = await ready();
      final premium = PremiumController(store)..load();
      await tester.pump();

      const karachi = JobLocation(latitude: 24.8607, longitude: 67.0111);

      final everyone = premium.directory(onlyWithinReach: false);
      final nearby = premium.directory(hirerAt: karachi);

      expect(
        nearby.length,
        lessThan(everyone.length),
        reason: 'a hirer in Karachi still saw every worker in Pakistan',
      );
      expect(
        nearby,
        isNotEmpty,
        reason: 'and the demo needs somebody left to book',
      );
    });

    testWidgets('and typing narrows it', (tester) async {
      // The script asks the presenter to type "kitchen".
      final store = await ready();
      final premium = PremiumController(store)..load();
      await tester.pump();

      final found = premium.directory(query: 'kitchen');

      expect(
        found,
        isNotEmpty,
        reason: 'the script tells the presenter to type kitchen; something '
            'has to come back',
      );
      expect(
        found.length,
        lessThan(premium.directory().length),
        reason: 'a search that returns everything is not a search',
      );
    });
  });

  group('stop 6 — Trust Hire staff, and oversight', () {
    testWidgets('has a queue to work through and a dispute to justify a CNIC',
        (tester) async {
      final store = await ready();
      final admin = AdminController(store)..load();
      await tester.pump();

      expect(admin.queue, isNotEmpty, reason: 'the approval queue is a stop');
      expect(
        admin.queue.any((review) => review.isFlagged),
        isTrue,
        reason: 'the script shows a flagged account sorting to the top',
      );

      expect(admin.openDisputes, isNotEmpty);

      // The CNIC door: openable for exactly the people a dispute names.
      final named = admin.openDisputes.first.aboutUserId;
      expect(admin.mayOpenCnic(named), isTrue);
      expect(
        admin.reviews.any((r) => !admin.mayOpenCnic(r.userId)),
        isTrue,
        reason: 'and closed for everybody else, which is the half that matters',
      );

      // Nothing is seeded into the log, so the demo starts from an empty one
      // and every line in it was made by whoever is demonstrating.
      expect(admin.log, isEmpty);
    });
  });

  group('stop 8 — the backend that is not there', () {
    testWidgets('posting with the connection off queues, and then drains',
        (tester) async {
      // **The stop that was fiction when it was written.** 0.15.0 shipped the
      // outbox, the panel and the rules, and nothing in `lib/` ever enqueued —
      // so the script's "turn the connection off and do something, the pill
      // says a change is waiting" would have failed in front of whoever
      // followed it. This test is why the script has one assertion per stop,
      // and it was added after the stop rather than with it.
      final store = await ready();
      final backend = MockBackend()..offline = true;
      final sync = SyncController(store, backend)..load();

      final jobs = JobRepository(
        store,
        MediaStore(store),
        const SeedLoader(),
        sync.enqueue,
      );

      await jobs.saveJob(
        Job(
          id: 'demo-1',
          location: const JobLocation(latitude: 33.7104, longitude: 73.0551),
          createdAt: DateTime(2026, 7, 28),
          tags: const {JobTag.plumbing},
          title: 'Tap dripping',
          postedBy: DemoAccounts.deviceId,
        ),
      );
      await tester.pump();

      // The save worked. It always works — that is the promise.
      expect((await jobs.fetchJobs()).any((job) => job.id == 'demo-1'), isTrue);
      expect(sync.outbox, hasLength(1));

      await sync.push();
      expect(sync.state(now: DateTime(2026, 7, 28)), SyncState.offline);

      backend.offline = false;
      await sync.push();
      expect(sync.outbox, isEmpty);
      expect(sync.state(now: DateTime(2026, 7, 28)), SyncState.settled);
    });

    testWidgets('and a refusal is shown rather than dropped', (tester) async {
      final store = await ready();
      final backend = MockBackend();
      final sync = SyncController(store, backend)..load();

      // Somebody accepted this job's offer elsewhere while we were away.
      await backend.push([
        PendingWrite(
          entity: RemoteEntity.job,
          id: 'demo-1',
          data: const {
            'postedBy': 'user-003',
            'acceptedWorkerId': 'user-009',
            'agreedFare': 1800,
          },
          madeAt: DateTime(2026, 7, 28),
        ),
      ]);

      await sync.enqueue(
        PendingWrite(
          entity: RemoteEntity.job,
          id: 'demo-1',
          data: const {
            'postedBy': 'user-003',
            'acceptedWorkerId': 'user-009',
            'agreedFare': 4000,
          },
          madeAt: DateTime(2026, 7, 28),
          baseVersion: 1,
        ),
      );
      await sync.push();

      expect(sync.needAttention, hasLength(1));
      expect(sync.needAttention.single.code, RefusalCode.fareIsLocked);
      await tester.pump();
    });
  });

  group('stop 7 — verification', () {
    testWidgets('a persona has a record to look at, the device account does not',
        (tester) async {
      final store = await ready();

      final usman = VerificationController(store)
        ..setAccount('user-009', name: 'Usman Raza');
      await tester.pump();

      expect(usman.mine.cnicOnFile, isTrue);
      expect(usman.mine.cnicMasked, contains('*'));
      expect(usman.mine.phoneVerified, isTrue);

      final device = VerificationController(store)..load();
      await tester.pump();

      expect(
        device.mine.isEmpty,
        isTrue,
        reason: 'the script walks the empty state on the device account',
      );
    });
  });
}
