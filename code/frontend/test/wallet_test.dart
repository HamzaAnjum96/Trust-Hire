import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/wallet_controller.dart';
import 'package:trust_hire/features/bidding/bidding_rules.dart';
import 'package:trust_hire/features/wallet/wallet_rules.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/models/wallet.dart';
import 'package:trust_hire/models/worker_profile.dart';
import 'package:trust_hire/services/local_store.dart';

/// Section 11.
///
/// The sprint's definition of done is "the wallet cannot reach an inconsistent
/// state", and the design answer is that there is no state to be inconsistent:
/// the ledger is stored and everything else is derived. So the first group
/// tests that claim directly, and the rest test the arithmetic on top of it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  const rules = WalletRules();
  final now = DateTime(2026, 7, 27, 10);

  Wallet walletWith(List<WalletEntry> entries) =>
      Wallet(userId: 'w', entries: entries);

  WalletEntry entry(
    WalletEntryKind kind,
    int tokens, {
    int minute = 0,
    String? jobId,
  }) => WalletEntry(
    id: '$kind-$minute-$tokens',
    kind: kind,
    tokens: tokens,
    createdAt: now.add(Duration(minutes: minute)),
    jobId: jobId,
  );

  group('the balance cannot disagree with the ledger', () {
    test('an empty wallet is empty', () {
      final wallet = Wallet(userId: 'w');
      expect(wallet.balance, 0);
      expect(wallet.lifetimeTopUp, 0);
      expect(wallet.entries, isEmpty);
    });

    test('the balance is the sum of what happened', () {
      final wallet = walletWith([
        entry(WalletEntryKind.topUp, 1000),
        entry(WalletEntryKind.commission, -75, minute: 1),
        entry(WalletEntryKind.firstJobCredit, 75, minute: 2),
      ]);

      expect(wallet.balance, 1000);
    });

    test('there is no way to move the balance without a reason', () {
      // The point of the design. Every path into a wallet appends entries, so
      // a balance that changed always has a line explaining it.
      final before = walletWith([entry(WalletEntryKind.topUp, 500)]);
      final after = before.withEntries(
        rules.onJobCompleted(
          wallet: before,
          jobId: 'j1',
          // Big enough that the first-job credit does not cover it, so the
          // balance actually moves.
          agreedFare: 20000,
          now: now,
        ),
      );

      expect(after.balance, isNot(before.balance));

      expect(after.entries.length, greaterThan(before.entries.length));
      expect(
        after.entries.fold<int>(0, (sum, e) => sum + e.tokens),
        after.balance,
      );
    });

    test('entries are replayed oldest first, however they arrive', () {
      // The debt count depends on the order, so the wallet sorts rather than
      // trusting the caller.
      final wallet = walletWith([
        entry(WalletEntryKind.commission, -100, minute: 5),
        entry(WalletEntryKind.topUp, 1000, minute: 1),
      ]);

      expect(wallet.entries.first.kind, WalletEntryKind.topUp);
      expect(wallet.balance, 900);
    });

    test('a ledger survives storage exactly', () {
      final wallet = walletWith([
        entry(WalletEntryKind.topUp, 5000),
        entry(WalletEntryKind.commission, -250, minute: 1, jobId: 'j1'),
      ]);

      final restored = Wallet.fromJson(wallet.toJson());
      expect(restored.balance, wallet.balance);
      expect(restored.entries.length, wallet.entries.length);
      expect(restored.entries.last.jobId, 'j1');
    });
  });

  group('commission', () {
    test('is five per cent of the agreed fare', () {
      expect(rules.commissionOn(2000), 100);
      expect(rules.commissionOn(25000), 1250);
    });

    test('rounds down, in the worker\'s favour', () {
      // At 5% the difference is at most a rupee, and it should fall toward the
      // person being charged.
      expect(rules.commissionOn(1990), 99);
      expect(rules.commissionOn(19), 0);
    });

    test('a fare too small to owe anything charges nothing', () {
      expect(
        rules.onJobCompleted(
          wallet: Wallet(userId: 'w'),
          jobId: 'j1',
          agreedFare: 10,
          now: now,
        ),
        isEmpty,
      );
    });
  });

  group('the first job credit', () {
    test('covers the first commission, up to Rs. 500', () {
      final entries = rules.onJobCompleted(
        wallet: Wallet(userId: 'w'),
        jobId: 'j1',
        agreedFare: 4000, // 5% = 200
        now: now,
      );

      final wallet = Wallet(userId: 'w', entries: entries);
      expect(wallet.balance, 0, reason: 'the first job should cost nothing');
      expect(
        entries
            .where((e) => e.kind == WalletEntryKind.commission)
            .single
            .tokens,
        -200,
      );
      expect(
        entries
            .where((e) => e.kind == WalletEntryKind.firstJobCredit)
            .single
            .tokens,
        200,
      );
    });

    test('the worker pays the difference above Rs. 500', () {
      // Section 11: "If the commission owed exceeds Rs. 500, the worker pays
      // the difference themselves."
      final entries = rules.onJobCompleted(
        wallet: Wallet(userId: 'w'),
        jobId: 'j1',
        agreedFare: 20000, // 5% = 1,000
        now: now,
      );

      expect(Wallet(userId: 'w', entries: entries).balance, -500);
    });

    test('it is not carried forward to a second job', () {
      var wallet = Wallet(userId: 'w');
      wallet = wallet.withEntries(
        rules.onJobCompleted(
          wallet: wallet,
          jobId: 'j1',
          agreedFare: 2000, // 5% = 100, fully credited
          now: now,
        ),
      );
      expect(wallet.balance, 0);

      wallet = wallet.withEntries(
        rules.onJobCompleted(
          wallet: wallet,
          jobId: 'j2',
          agreedFare: 2000,
          now: now.add(const Duration(days: 1)),
        ),
      );

      // The unused Rs. 400 does not follow them: the credit is tied to the
      // first job.
      expect(wallet.balance, -100);
      expect(
        wallet.entries.where((e) => e.kind == WalletEntryKind.firstJobCredit),
        hasLength(1),
      );
    });

    test('the commission is recorded in full, not netted off', () {
      // Netting would hide the 5% behind a smaller number and make the ledger
      // useless as an explanation of what the platform took.
      final entries = rules.onJobCompleted(
        wallet: Wallet(userId: 'w'),
        jobId: 'j1',
        agreedFare: 4000,
        now: now,
      );

      expect(entries, hasLength(2));
      expect(entries.first.kind, WalletEntryKind.commission);
    });
  });

  group('the loyalty bonus', () {
    test('lands each time lifetime top-up crosses Rs. 100,000', () {
      var wallet = Wallet(userId: 'w');

      wallet = wallet.withEntries(
        rules.onTopUp(wallet: wallet, tokens: 60000, now: now),
      );
      expect(wallet.loyaltyBonusesGranted, 0);

      wallet = wallet.withEntries(
        rules.onTopUp(wallet: wallet, tokens: 50000, now: now),
      );
      expect(wallet.loyaltyBonusesGranted, 1);
      expect(wallet.balance, 111000);
    });

    test('recurs, rather than paying once', () {
      var wallet = Wallet(userId: 'w');
      for (var i = 0; i < 3; i++) {
        wallet = wallet.withEntries(
          rules.onTopUp(wallet: wallet, tokens: 100000, now: now),
        );
      }

      expect(wallet.loyaltyBonusesGranted, 3);
    });

    test('a single large top-up pays every bonus it crossed', () {
      // Computed from the totals rather than triggered at a crossing, so a
      // jump from nothing to Rs. 250,000 is owed two.
      final wallet = Wallet(userId: 'w').withEntries(
        rules.onTopUp(
          wallet: Wallet(userId: 'w'),
          tokens: 250000,
          now: now,
        ),
      );

      expect(wallet.loyaltyBonusesGranted, 2);
    });

    test('spending does not undo having bought', () {
      var wallet = Wallet(userId: 'w').withEntries(
        rules.onTopUp(
          wallet: Wallet(userId: 'w'),
          tokens: 100000,
          now: now,
        ),
      );
      wallet = wallet.withEntries([
        entry(WalletEntryKind.commission, -99000, minute: 1),
      ]);

      // Lifetime top-up is a total, not a balance, so the next Rs. 100,000
      // still earns the second bonus.
      expect(wallet.lifetimeTopUp, 100000);
      expect(rules.loyaltyBonusesDue(wallet, now: now), isEmpty);
    });

    test('a bonus is never paid twice for the same money', () {
      final wallet = Wallet(userId: 'w').withEntries(
        rules.onTopUp(
          wallet: Wallet(userId: 'w'),
          tokens: 100000,
          now: now,
        ),
      );

      expect(rules.loyaltyBonusesDue(wallet, now: now), isEmpty);
    });
  });

  group('debt and lockout', () {
    test('one unpaid job is tolerated', () {
      // A worker who cannot afford the commission is exactly the worker who
      // needs the next job.
      final wallet = walletWith([
        entry(WalletEntryKind.commission, -1000, jobId: 'j1'),
      ]);

      expect(wallet.balance, -1000);
      expect(wallet.unpaidJobs, 1);
      expect(rules.isLockedOut(wallet), isFalse);
      expect(rules.canTakeWork(wallet), isTrue);
    });

    test('a second unpaid job locks the account', () {
      // Section 11: "a second job goes unpaid on top of that".
      final wallet = walletWith([
        entry(WalletEntryKind.commission, -1000, jobId: 'j1'),
        entry(WalletEntryKind.commission, -500, minute: 1, jobId: 'j2'),
      ]);

      expect(wallet.unpaidJobs, 2);
      expect(rules.isLockedOut(wallet), isTrue);
      expect(rules.canTakeWork(wallet), isFalse);
    });

    test('an admin deduction is not an unpaid job', () {
      // **Only a commission counts.** An admin correcting a balance downward,
      // or a cancellation penalty, can leave a worker short — but neither is a
      // job they took and did not pay for, and counting them would push
      // somebody toward a lockout for a mistake staff were putting right.
      //
      // Found by `tool/sweep_tests.py`: dropping the `kind` check from
      // `unpaidJobs` left the whole suite green.
      final corrected = walletWith([
        entry(WalletEntryKind.topUp, 1000),
        entry(WalletEntryKind.adminAdjustment, -1500, minute: 1),
      ]);

      expect(corrected.balance, -500, reason: 'the worker really is short');
      expect(corrected.unpaidJobs, 0);
      expect(rules.isLockedOut(corrected), isFalse);

      // Two of them still do not add up to a lockout, however deep the hole.
      final twice = walletWith([
        entry(WalletEntryKind.adminAdjustment, -400),
        entry(WalletEntryKind.cancellationPenalty, -400, minute: 1),
      ]);

      expect(twice.unpaidJobs, 0);
      expect(rules.isLockedOut(twice), isFalse);
    });

    test('a commission charged while already short still counts once each', () {
      // The half of the same rule that must keep working: two commissions in
      // the red are two unpaid jobs, whatever else is in the ledger.
      final wallet = walletWith([
        entry(WalletEntryKind.adminAdjustment, -200),
        entry(WalletEntryKind.commission, -300, minute: 1, jobId: 'j1'),
        entry(WalletEntryKind.commission, -300, minute: 2, jobId: 'j2'),
      ]);

      expect(wallet.unpaidJobs, 2);
      expect(rules.isLockedOut(wallet), isTrue);
    });

    test('recovering in between resets the count', () {
      // The debt is what is owed now, not a record of every time the worker
      // has been short. Someone who paid up is not one strike from a lockout
      // forever.
      final wallet = walletWith([
        entry(WalletEntryKind.commission, -1000, jobId: 'j1'),
        entry(WalletEntryKind.topUp, 1000, minute: 1),
        entry(WalletEntryKind.commission, -400, minute: 2, jobId: 'j2'),
      ]);

      expect(wallet.unpaidJobs, 1);
      expect(rules.isLockedOut(wallet), isFalse);
    });

    test('a partial top-up that does not clear the debt does not unlock', () {
      final wallet = walletWith([
        entry(WalletEntryKind.commission, -1000, jobId: 'j1'),
        entry(WalletEntryKind.commission, -500, minute: 1, jobId: 'j2'),
        entry(WalletEntryKind.topUp, 200, minute: 2),
      ]);

      expect(wallet.balance, -1300);
      expect(rules.isLockedOut(wallet), isTrue);
    });

    test('topping up clears the lock', () {
      final owing = walletWith([
        entry(WalletEntryKind.commission, -1000, jobId: 'j1'),
      ]);

      final cleared = owing.withEntries(
        rules.onTopUp(
          wallet: owing,
          tokens: 2000,
          now: now.add(const Duration(minutes: 1)),
        ),
      );

      expect(cleared.unpaidJobs, 0);
      expect(rules.isLockedOut(cleared), isFalse);
      expect(cleared.balance, 1000);
    });

    test('a positive balance is never in debt', () {
      final wallet = walletWith([
        entry(WalletEntryKind.topUp, 5000),
        entry(WalletEntryKind.commission, -250, minute: 1, jobId: 'j1'),
      ]);

      expect(wallet.unpaidJobs, 0);
      expect(rules.canTakeWork(wallet), isTrue);
    });

    test('a locked worker cannot bid', () {
      const bidding = BiddingRules();
      final job = Job(
        id: 'j',
        location: const JobLocation(latitude: 33.7, longitude: 73.0),
        createdAt: now,
        tags: const {JobTag.misc},
      );

      expect(
        bidding.refusalFor(
          job,
          worker: WorkerProfile(userId: 'w'),
          from: const JobLocation(latitude: 33.7, longitude: 73.0),
          existingBids: const [],
          walletLocked: true,
        ),
        BidRefusal.walletLocked,
      );
    });
  });

  group('the cancellation penalty', () {
    test('is charged to the worker who walked away', () {
      final entries = rules.onWorkerCancelled(jobId: 'j1', now: now);

      expect(entries.single.tokens, -WalletRules.cancellationPenaltyTokens);
      expect(entries.single.jobId, 'j1');
    });

    test('is flat, not a share of the fare', () {
      // The harm to the hirer is much the same whatever the job was worth,
      // and a percentage would make walking away from a large job ruinous.
      expect(WalletRules.cancellationPenaltyTokens, greaterThan(0));
      final small = rules.onWorkerCancelled(jobId: 'small', now: now).single;
      final large = rules.onWorkerCancelled(jobId: 'large', now: now).single;
      expect(small.tokens, large.tokens);
    });
  });

  group('the controller', () {
    Future<WalletController> controller() async {
      final store = await LocalStore.open();
      return WalletController(store)..load();
    }

    test('records a completion once, however many times it is told', () async {
      // A retry or a double tap must not charge twice.
      final wallet = await controller();

      await wallet.recordCompletion(jobId: 'j1', agreedFare: 20000, at: now);
      final afterFirst = wallet.balance;

      await wallet.recordCompletion(jobId: 'j1', agreedFare: 20000, at: now);

      expect(wallet.balance, afterFirst);
      expect(
        wallet.wallet.entries.where(
          (e) => e.kind == WalletEntryKind.commission,
        ),
        hasLength(1),
      );
    });

    test('records a cancellation once', () async {
      final wallet = await controller();

      await wallet.recordWorkerCancellation(jobId: 'j1', at: now);
      await wallet.recordWorkerCancellation(jobId: 'j1', at: now);

      expect(
        wallet.wallet.entries.where(
          (e) => e.kind == WalletEntryKind.cancellationPenalty,
        ),
        hasLength(1),
      );
    });

    test('the ledger survives a restart', () async {
      final store = await LocalStore.open();
      final first = WalletController(store)..load();
      await first.topUp(5000, at: now);
      await first.recordCompletion(jobId: 'j1', agreedFare: 20000, at: now);

      final second = WalletController(store)..load();

      expect(second.balance, first.balance);
      expect(second.wallet.entries.length, first.wallet.entries.length);
    });

    test(
      'a corrupt ledger starts empty rather than inventing a debt',
      () async {
        final store = await LocalStore.open();
        await store.writeString(StoreKeys.wallet, 'not json');

        final wallet = WalletController(store)..load();

        expect(wallet.balance, 0);
        expect(wallet.isLockedOut, isFalse);
      },
    );

    test('a zero or negative top-up does nothing', () async {
      final wallet = await controller();

      await wallet.topUp(0, at: now);
      await wallet.topUp(-500, at: now);

      expect(wallet.wallet.entries, isEmpty);
    });
  });

  test('a worker\'s first year, end to end', () async {
    // The rules interact, so one run through them all: a first job that costs
    // nothing, a second that puts them in debt, a top-up that clears it and
    // earns a bonus, and a cancellation on top.
    final store = await LocalStore.open();
    final wallet = WalletController(store)..load();

    await wallet.recordCompletion(jobId: 'j1', agreedFare: 6000, at: now);
    expect(wallet.balance, 0, reason: 'first job covered by the credit');

    await wallet.recordCompletion(jobId: 'j2', agreedFare: 20000, at: now);
    expect(wallet.balance, -1000);
    expect(wallet.isInDebt, isTrue);
    expect(wallet.isLockedOut, isFalse, reason: 'one unpaid job is allowed');

    await wallet.topUp(100000, at: now);
    expect(wallet.wallet.loyaltyBonusesGranted, 1);
    expect(wallet.balance, -1000 + 100000 + 1000);
    expect(wallet.isInDebt, isFalse);

    await wallet.recordWorkerCancellation(jobId: 'j3', at: now);
    expect(wallet.balance, 99800);

    // And the ledger still explains every rupee of it.
    expect(
      wallet.wallet.entries.fold<int>(0, (sum, e) => sum + e.tokens),
      wallet.balance,
    );
  });
}
