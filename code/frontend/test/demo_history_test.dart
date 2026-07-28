import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/account_controller.dart';
import 'package:trust_hire/app/bootstrap.dart';
import 'package:trust_hire/app/profile_controller.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/app/rating_controller.dart';
import 'package:trust_hire/app/wallet_controller.dart';
import 'package:trust_hire/features/feed/job_visibility.dart';
import 'package:trust_hire/features/wallet/wallet_rules.dart';
import 'package:trust_hire/models/account.dart';
import 'package:trust_hire/models/bid.dart';
import 'package:trust_hire/models/job_status.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/models/rating.dart';
import 'package:trust_hire/models/wallet.dart';
import 'package:trust_hire/services/bid_repository.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';

import 'support/surface.dart';

/// The seed's **past**, not its contents.
///
/// Jobs that have only just been posted make half of Phase 1 invisible: no
/// offers to choose between, nobody with a record, and every wallet empty. So
/// the generator gives the demo a history — and a history is a set of facts
/// that have to agree with each other. A completed job whose worker was never
/// charged, or a locked-out worker whose ledger is in credit, would be a
/// demonstration of a bug rather than of a rule.
///
/// These check the agreement, not the numbers. Asserting "user-016 owes
/// Rs. 2,025" would break every time the generator's random seed is touched
/// and would say nothing about whether the data is coherent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  Future<LocalStore> seeded() async {
    final store = await LocalStore.open();
    await JobRepository(store, MediaStore(store)).ensureSeeded();
    return store;
  }

  group('what the seed writes', () {
    test('is exactly this set, and the reset screen reloads all of it',
        () async {
      // **A tripwire, not a description.** Restoring the seed replaces every
      // key below, and each one is already held in memory by some controller.
      // The reset handler in `profile_screen.dart` has to re-read all of them
      // or the app shows a restored map beside stale balances — and the next
      // write puts the stale ones back.
      //
      // Nothing can make a widget method enumerate itself, so this fails when
      // the seed grows a key instead. If you are reading this because the test
      // broke: add the new key's controller to `_confirmReset`, then add the
      // key here.
      const reloadedOnReset = <String>{
        StoreKeys.jobs, // JobController
        StoreKeys.users, // JobController
        StoreKeys.bids, // BidController
        StoreKeys.ratings, // RatingController
        StoreKeys.directory, // PremiumController
        StoreKeys.accountReviews, // AdminController
        StoreKeys.cnicRecords, // AdminController
        StoreKeys.disputes, // AdminController
      };

      // Per-account keys are written suffixed, and read back by the
      // controllers that follow the active account — ProfileController and
      // WalletController, both of which the reset handler reloads.
      const perAccount = <String>{StoreKeys.role, StoreKeys.workerProfile,
          StoreKeys.wallet};

      final store = await LocalStore.open();
      await JobRepository(store, MediaStore(store)).ensureSeeded();

      for (final key in reloadedOnReset) {
        expect(
          store.readCollection(key) ?? store.readString(key),
          isNotNull,
          reason: '$key is expected to be seeded but was not written',
        );
      }

      // And the seed writes nothing outside that set except the flag, the
      // per-account keys, and the preferences the seed never touches.
      final known = {
        ...reloadedOnReset,
        StoreKeys.seeded,
        StoreKeys.activeAccount,
        StoreKeys.introSeen,
        StoreKeys.themeMode,
        StoreKeys.language,
        StoreKeys.savedJobs,
        StoreKeys.tradesNoticeDismissed,
        StoreKeys.mediaIndex,
        ...perAccount,
      };

      final written = SharedPreferences.getInstance();
      final prefs = await written;
      final unexpected = prefs
          .getKeys()
          .where((key) => key.startsWith(StoreKeys.prefix))
          // Per-account keys are `<key>#<account>`.
          .map((key) => key.split('#').first)
          .where((key) => !known.contains(key))
          .toSet();

      expect(
        unexpected,
        isEmpty,
        reason: 'the seed writes $unexpected, which no controller reloads on '
            'a restore — see _confirmReset in profile_screen.dart',
      );
    });
  });

  group('the demo has a past', () {
    test('work in every state, so no screen is unreachable', () async {
      final store = await seeded();
      final jobs = await JobRepository(store, MediaStore(store)).fetchJobs();

      for (final status in JobStatus.values) {
        if (status == JobStatus.expired) continue;

        expect(
          jobs.where((job) => job.status == status),
          isNotEmpty,
          reason: 'nothing in the demo is $status',
        );
      }
    });

    test('a finished job has somebody who finished it', () async {
      final store = await seeded();
      final jobs = await JobRepository(store, MediaStore(store)).fetchJobs();

      for (final job in jobs.where((job) => job.status.hasWorker)) {
        expect(job.acceptedWorkerId, isNotNull, reason: job.id);
        expect(job.agreedFare, isNotNull, reason: job.id);
      }
    });

    test('nobody is bidding on their own job', () async {
      final store = await seeded();
      final jobs = await JobRepository(store, MediaStore(store)).fetchJobs();
      final bids = await BidRepository(store).fetchBids();

      final poster = {for (final job in jobs) job.id: job.postedBy};

      for (final bid in bids) {
        expect(
          bid.workerId,
          isNot(poster[bid.jobId]),
          reason: '${bid.workerId} offered on their own job ${bid.jobId}',
        );
      }
    });

    test('one accepted bid per job at most', () async {
      final store = await seeded();
      final bids = await BidRepository(store).fetchBids();

      final acceptedPerJob = <String, int>{};
      for (final bid in bids.where((b) => b.status == BidStatus.accepted)) {
        acceptedPerJob[bid.jobId] = (acceptedPerJob[bid.jobId] ?? 0) + 1;
      }

      for (final entry in acceptedPerJob.entries) {
        expect(entry.value, 1, reason: '${entry.key} has two winners');
      }
    });

    test('ratings only ever attach to finished work', () async {
      // Section 10 refuses to rate anything else, so seeded data that did
      // would be showing a state the app cannot produce.
      final store = await seeded();
      final jobs = await JobRepository(store, MediaStore(store)).fetchJobs();
      final ratings = RatingController(store)..load();

      final status = {for (final job in jobs) job.id: job.status};

      for (final rating in ratings.all) {
        expect(
          status[rating.jobId],
          JobStatus.completed,
          reason: '${rating.jobId} is rated but not finished',
        );
      }
    });

    test('and one per side per job at most', () async {
      final store = await seeded();
      final ratings = (RatingController(store)..load()).all;

      final seen = <String>{};
      for (final rating in ratings) {
        final key = '${rating.jobId}/${rating.side.id}';
        expect(seen.add(key), isTrue, reason: 'two $key ratings');
      }
    });

    test('workers have records worth reading', () async {
      // The point of the whole exercise: a hirer looking at a list of offers
      // should mostly see people with a history behind them.
      final store = await seeded();
      final jobs = await JobRepository(store, MediaStore(store)).fetchJobs();
      final ratings = RatingController(store)..load();

      final rated = ratings.all
          .where((r) => r.side == RatedSide.worker)
          .map((r) => r.jobId)
          .toSet();

      final workers = jobs
          .where((job) => rated.contains(job.id))
          .map((job) => job.acceptedWorkerId)
          .whereType<String>()
          .toSet();

      expect(workers.length, greaterThan(10));

      for (final worker in workers) {
        expect(
          ratings.standingFor(worker, jobs: jobs).hasHistory,
          isTrue,
          reason: '$worker was rated but has no finished jobs',
        );
      }
    });
  });

  group("the demo accounts' own postings", () {
    // The gap this closes: the random pass draws from jobs posted by *other*
    // people, so for a long time a persona's own postings were bare open jobs
    // with nothing on them. Switching to a demo account and opening "Posted"
    // showed the hirer's side of Mode A with no decision to make — which is
    // the half of Mode A that the hirer's side *is*.
    test('have offers to choose between', () async {
      final store = await seeded();
      final jobs = await JobRepository(store, MediaStore(store)).fetchJobs();
      final bids = await BidRepository(store).fetchBids();

      final offersOn = <String, int>{};
      for (final bid in bids) {
        offersOn[bid.jobId] = (offersOn[bid.jobId] ?? 0) + 1;
      }

      for (final account in DemoAccounts.roster) {
        if (!account.isSeeded) continue;

        final mine = jobs
            .where((job) => job.isPostedBy(account.id))
            .toList(growable: false);

        expect(mine, isNotEmpty, reason: '${account.name} posted nothing');
        expect(
          mine.where((job) => (offersOn[job.id] ?? 0) > 0).length,
          greaterThan(1),
          reason: '${account.name} has almost nothing to review',
        );
      }
    });

    test('include something finished and rated', () async {
      final store = await seeded();
      final jobs = await JobRepository(store, MediaStore(store)).fetchJobs();
      final ratings = (RatingController(store)..load()).all;
      final rated = ratings.map((rating) => rating.jobId).toSet();

      for (final account in DemoAccounts.roster) {
        if (!account.isSeeded) continue;

        final mine = jobs.where((job) => job.isPostedBy(account.id));

        expect(
          mine.where(
            (job) => job.status == JobStatus.completed && rated.contains(job.id),
          ),
          isNotEmpty,
          reason: '${account.name} has no finished, rated posting',
        );
      }
    });

    test('and reach more than one state between them', () async {
      // Open, finished, and one under way at minimum — the three a hirer
      // needs to be able to point at.
      final store = await seeded();
      final jobs = await JobRepository(store, MediaStore(store)).fetchJobs();

      for (final account in DemoAccounts.roster) {
        if (!account.isSeeded) continue;

        final states = jobs
            .where((job) => job.isPostedBy(account.id))
            .map((job) => job.status)
            .toSet();

        expect(
          states.length,
          greaterThanOrEqualTo(3),
          reason: '${account.name}\'s postings are all in one state',
        );
      }
    });

    test('and every commission matches a job that worker finished', () async {
      // The ledgers are built from one list of completions, so a persona is
      // charged for all their work rather than for whichever loop happened to
      // create it. This is the check that the two still agree.
      final store = await seeded();
      final jobs = await JobRepository(store, MediaStore(store)).fetchJobs();

      for (final account in DemoAccounts.roster) {
        if (!account.isSeeded) continue;

        final wallet = (WalletController(store)..setAccount(account.id)).wallet;
        final charged = wallet.entries
            .where((entry) => entry.kind == WalletEntryKind.commission)
            .map((entry) => entry.jobId)
            .toSet();

        final finished = jobs
            .where((job) => job.isCompletedBy(account.id))
            .map((job) => job.id)
            .toSet();

        expect(
          charged,
          finished,
          reason: '${account.name} was charged for work they did not do, '
              'or did work they were not charged for',
        );
      }
    });
  });

  group('the demo accounts', () {
    test('differ from each other, which is the point of having five', () async {
      final store = await seeded();

      final balances = <int>[];
      final tradeCounts = <int>[];

      for (final account in DemoAccounts.roster) {
        if (!account.isSeeded) continue;

        final wallet = WalletController(store)..setAccount(account.id);
        final profile = ProfileController(store)..setAccount(account.id);

        balances.add(wallet.balance);
        tradeCounts.add(profile.specialities.length);
      }

      expect(
        balances.toSet().length,
        greaterThan(3),
        reason: 'five identical wallets demonstrate nothing',
      );
      expect(tradeCounts.toSet().length, greaterThan(2));
    });

    test('include one worker who cannot take work', () async {
      // Section 11's lockout is the hardest state to reach by hand — it needs
      // two commissions charged while already short — and the easiest to get
      // wrong. Somebody in the switcher is always in it.
      final store = await seeded();

      final locked = DemoAccounts.roster.where((account) {
        if (!account.isSeeded) return false;
        final wallet = WalletController(store)..setAccount(account.id);
        return wallet.isLockedOut;
      });

      expect(locked, isNotEmpty);
    });

    test('include one worker in good standing', () async {
      final store = await seeded();

      final clear = DemoAccounts.roster.where((account) {
        if (!account.isSeeded) return false;
        final wallet = WalletController(store)..setAccount(account.id);
        return wallet.canTakeWork && wallet.balance > 1000;
      });

      expect(clear, isNotEmpty);
    });

    test('include a hirer, whose wallet is beside the point', () async {
      final store = await seeded();

      final hirers = DemoAccounts.roster.where((account) {
        if (!account.isSeeded) return false;
        final profile = ProfileController(store)..setAccount(account.id);
        return !profile.isWorker;
      });

      expect(hirers, isNotEmpty);
    });

    test('every seeded wallet obeys the commission rule', () async {
      // The ledger is the only stored state, so a seeded one has to be
      // something the rules could themselves have produced. A commission that
      // is not 5% of a real agreed fare would put a number on the wallet
      // screen that the app can never reach.
      const rules = WalletRules();
      final store = await seeded();
      final jobs = await JobRepository(store, MediaStore(store)).fetchJobs();
      final fares = {for (final job in jobs) job.id: job.agreedFare};

      for (final account in DemoAccounts.roster) {
        if (!account.isSeeded) continue;

        final wallet = WalletController(store)..setAccount(account.id);

        for (final entry in wallet.wallet.entries) {
          if (entry.kind != WalletEntryKind.commission) continue;

          final fare = fares[entry.jobId];
          expect(fare, isNotNull, reason: '${entry.jobId} was charged for');
          expect(
            -entry.tokens,
            rules.commissionOn(fare!),
            reason: 'charge on ${entry.jobId}',
          );
        }
      }
    });

    test('a first-job credit never exceeds what was owed', () async {
      final store = await seeded();

      for (final account in DemoAccounts.roster) {
        if (!account.isSeeded) continue;

        final wallet = (WalletController(store)..setAccount(account.id)).wallet;
        final credits = wallet.entries.where(
          (e) => e.kind == WalletEntryKind.firstJobCredit,
        );

        expect(
          credits.length,
          lessThanOrEqualTo(1),
          reason: '${account.id} got the first-job credit twice',
        );

        for (final credit in credits) {
          final charge = wallet.entries.firstWhere(
            (e) =>
                e.kind == WalletEntryKind.commission &&
                e.jobId == credit.jobId,
          );
          expect(credit.tokens, lessThanOrEqualTo(-charge.tokens));
          expect(
            credit.tokens,
            lessThanOrEqualTo(WalletRules.firstJobCreditTokens),
          );
        }
      }
    });

    test('the device account starts clean', () async {
      // The one account with no history. Somebody trying the app for the
      // first time should see what a new user sees, not somebody else's
      // balance and trades.
      final store = await seeded();

      final wallet = WalletController(store)..load();
      final profile = ProfileController(store)..load();

      expect(wallet.balance, 0);
      expect(profile.specialities, isEmpty);
      expect(profile.tags, JobTag.defaultWorkerTags);
    });
  });

  group('the app shows a persona their own history', () {
    // Through the same bootstrap `main()` uses. Building the app without it
    // is testing a different app: the four identity controllers read storage
    // the moment they are constructed, so a seed that has not landed by then
    // shows a busy worker an empty Offers tab.
    Future<void> pumpAs(WidgetTester tester, DemoAccount account) async {
      final store = await bootstrap();
      await (SettingsController(store)..load()).markIntroSeen();
      await (AccountController(store)..load()).switchTo(account);

      await tester.useCompactSurface();
      await tester.pumpWidget(TrustHireApp(store: store));

      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('offers, including the ones that went nowhere', (tester) async {
      final usman = DemoAccounts.byId('user-009');
      await pumpAs(tester, usman);

      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      // The exact count comes from the generator and will move; that it is
      // not zero is the thing this is here to catch.
      final label = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .firstWhere((data) => data.startsWith('Offers · '));
      final count = int.parse(label.split(' · ').last);

      expect(count, greaterThan(0), reason: 'the seed did not land in time');
    });

    testWidgets('and a wallet with something in it', (tester) async {
      await pumpAs(tester, DemoAccounts.byId('user-009'));

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Rs. 0'), findsNothing);
    });
  });

  group('offers a worker can look back at', () {
    test('somebody in the switcher has been passed over', () async {
      final store = await seeded();
      final bids = await BidRepository(store).fetchBids();

      final losers = bids
          .where((bid) => bid.status == BidStatus.passedOver)
          .map((bid) => bid.workerId)
          .toSet();

      final personas = DemoAccounts.roster
          .where((account) => account.isSeeded)
          .map((account) => account.id)
          .toSet();

      expect(
        losers.intersection(personas),
        isNotEmpty,
        reason: 'no demo account can see what being passed over looks like',
      );
    });

    test('and never on work the tag rule would have hidden', () async {
      // Section 8 decides which jobs reach which worker. A seeded offer on a
      // job its bidder could never have seen would put a state on the screen
      // the app cannot produce — and it is the detail somebody looking closely
      // at the demo notices first.
      final store = await seeded();
      final jobs = await JobRepository(store, MediaStore(store)).fetchJobs();
      final bids = await BidRepository(store).fetchBids();

      final byId = {for (final job in jobs) job.id: job};

      for (final account in DemoAccounts.roster) {
        if (!account.isSeeded) continue;

        final profile = (ProfileController(store)..setAccount(account.id))
            .profile;

        for (final bid in bids.where((b) => b.workerId == account.id)) {
          expect(
            JobVisibility.overlaps(byId[bid.jobId]!.tags, profile.tags),
            isTrue,
            reason:
                '${account.name} offered on ${bid.jobId}, which their trades '
                'would never have shown them',
          );
        }
      }
    });

    test('and somebody is still waiting on an answer', () async {
      final store = await seeded();
      final bids = await BidRepository(store).fetchBids();

      final waiting = bids
          .where((bid) => bid.status == BidStatus.offered)
          .map((bid) => bid.workerId)
          .toSet();

      final personas = DemoAccounts.roster
          .where((account) => account.isSeeded)
          .map((account) => account.id)
          .toSet();

      expect(waiting.intersection(personas), isNotEmpty);
    });
  });

  group('a worker reads their own trades', () {
    test('with general work first', () {
      // It is the one they already hold and the one that cannot be switched
      // off. Eighteenth in the list, the tile that answers "will I still see
      // general jobs?" was the last one anybody found.
      expect(JobTag.workerOrder.first, JobTag.misc);
      expect(JobTag.workerOrder.toSet(), JobTag.values.toSet());
      expect(JobTag.workerOrder, hasLength(JobTag.values.length));
    });

    test('but a hirer picks tags in the declared order', () {
      // There, general work is the fallback for somebody who cannot name the
      // trade they need. First would make it the path of least resistance and
      // quietly undo the rule the whole of Section 8 rests on.
      expect(JobTag.values.first, isNot(JobTag.misc));
    });
  });

  group('the add-a-trade notice', () {
    test('can be closed, and stays closed', () async {
      final store = await LocalStore.open();
      final profile = ProfileController(store)..load();

      expect(profile.tradesNoticeDismissed, isFalse);
      await profile.dismissTradesNotice();

      final reopened = ProfileController(store)..load();
      expect(reopened.tradesNoticeDismissed, isTrue);
    });

    test('separately for each account', () async {
      // It is advice about one person's feed. Closing it as one demo account
      // should not hide it from the next, who has not read it.
      final store = await LocalStore.open();
      final profile = ProfileController(store)..load();
      await profile.dismissTradesNotice();

      profile.setAccount('user-017');
      expect(profile.tradesNoticeDismissed, isFalse);

      profile.setAccount(DemoAccounts.deviceId);
      expect(profile.tradesNoticeDismissed, isTrue);
    });

    test('closing it does not narrow the feed', () async {
      // The notice explains a rule; dismissing it is about the notice, not
      // about the rule. A worker who closes it still sees general work.
      final store = await LocalStore.open();
      final profile = ProfileController(store)..load();

      final before = profile.tags;
      await profile.dismissTradesNotice();

      expect(profile.tags, before);
      expect(profile.tags, contains(JobTag.misc));
    });
  });
}
