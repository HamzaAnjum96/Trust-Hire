import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trust_hire/app/admin_controller.dart';
import 'package:trust_hire/app/wallet_controller.dart';
import 'package:trust_hire/features/admin/admin_rules.dart';
import 'package:trust_hire/features/wallet/wallet_rules.dart';
import 'package:trust_hire/models/account.dart';
import 'package:trust_hire/models/admin.dart';
import 'package:trust_hire/models/verification.dart';
import 'package:trust_hire/models/wallet.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';

/// Section 12 — and two claims in it that are worth more than the screens.
///
/// The first: **every admin action is logged.** An admin panel is a set of
/// powers to override the rules the rest of the app enforces, and the only
/// thing that makes that acceptable is that each use is written down. So the
/// tests here are less about what an override does than about whether it can
/// happen quietly. It cannot: `AdminController._perform` records first and
/// changes second, and it is the only path.
///
/// The second: **a CNIC is opened on a dispute or not at all.** Section 2 says
/// the photo "sits unreviewed unless a dispute is raised later". That is an
/// access rule about somebody's national identity document, and a rule of that
/// kind should not live in a screen that could be rebuilt without it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  const rules = AdminRules();
  final now = DateTime(2026, 7, 27, 10);

  Dispute dispute({
    String id = 'd1',
    String about = 'user-009',
    bool open = true,
  }) => Dispute(
    id: id,
    jobId: 'job-1',
    aboutUserId: about,
    raisedByUserId: 'user-003',
    raisedAt: now,
    reason: 'Did not turn up.',
    resolvedAt: open ? null : now,
    resolution: open ? null : 'Settled.',
  );

  Future<AdminController> admin() async {
    final store = await LocalStore.open();
    return AdminController(store)..load();
  }

  Future<AdminController> seededAdmin() async {
    final store = await LocalStore.open();
    await JobRepository(store, MediaStore(store)).ensureSeeded();
    return AdminController(store)..load();
  }

  group('the CNIC opens on a dispute, or not at all', () {
    test('an open dispute about them unlocks it', () {
      expect(
        rules.mayOpenCnic('user-009', disputes: [dispute()]),
        isTrue,
      );
    });

    test('nothing else does', () {
      expect(rules.mayOpenCnic('user-009', disputes: const []), isFalse);

      // A dispute about somebody else is not a reason to look at this
      // person's identity document.
      expect(
        rules.mayOpenCnic('user-009', disputes: [dispute(about: 'user-016')]),
        isFalse,
      );

      // And a settled one closes the door again. The reason to look was the
      // complaint, and the complaint is finished.
      expect(
        rules.mayOpenCnic('user-009', disputes: [dispute(open: false)]),
        isFalse,
      );
    });

    test('the controller refuses, and records nothing when it does', () async {
      // A refusal is not an inspection. Logging one would put a line in the
      // record saying somebody looked at a document they never saw.
      final panel = await seededAdmin();

      final unwatched = panel.reviews
          .map((review) => review.userId)
          .firstWhere((id) => !panel.mayOpenCnic(id));

      expect(await panel.openCnic(unwatched, note: 'curious'), isNull);
      expect(panel.log, isEmpty);
    });

    test('and logs it when it allows', () async {
      final panel = await seededAdmin();

      final watched = panel.openDisputes.first.aboutUserId;
      final record = await panel.openCnic(watched, note: 'checking the name');

      expect(record, isNotNull);
      expect(panel.log.single.action, AdminAction.viewCnic);
      expect(panel.log.single.targetUserId, watched);
      expect(panel.log.single.note, 'checking the name');
    });

    test('and never stores a whole CNIC number', () async {
      // The app has no use for a full national identity number, and Section 13
      // rules out looking one up. What is kept is enough to match a document
      // against a claim and no more.
      final panel = await seededAdmin();
      final watched = panel.openDisputes.first.aboutUserId;

      final record = await panel.openCnic(watched, note: 'checking');
      expect(record!.maskedNumber, contains('*'));
      expect(RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(record.maskedNumber), isFalse);
    });
  });

  group('nothing happens without a line in the log', () {
    test('approving', () async {
      final panel = await admin();
      await panel.approve('user-009');

      expect(panel.reviewOf('user-009').status, ReviewStatus.approved);
      expect(panel.log, hasLength(1));
      expect(panel.log.single.action, AdminAction.approveUser);
    });

    test('suspending, and it carries the reason', () async {
      final panel = await admin();
      await panel.suspend('user-009', note: 'Three no-shows in a week.');

      expect(panel.reviewOf('user-009').status, ReviewStatus.suspended);
      expect(panel.log.single.note, 'Three no-shows in a week.');
    });

    test('adjusting a balance', () async {
      final panel = await admin();
      await panel.adjustWallet('user-009', tokens: -500, note: 'Chargeback.');

      expect(panel.walletOf('user-009').balance, -500);
      expect(panel.log.single.action, AdminAction.adjustWallet);
      expect(panel.log.single.tokens, -500);
    });

    test('and the log survives a reload', () async {
      final store = await LocalStore.open();
      final panel = AdminController(store)..load();
      await panel.suspend('user-009', note: 'Reported by two hirers.');

      final reopened = AdminController(store)..load();
      expect(reopened.log, hasLength(1));
      expect(reopened.reviewOf('user-009').status, ReviewStatus.suspended);
    });

    test('the log is never edited or thinned', () async {
      final panel = await admin();

      await panel.approve('user-009');
      await panel.suspend('user-009', note: 'Reported.');
      await panel.reinstate('user-009', note: 'Explained itself.');

      // Three decisions about one person, and all three are still readable.
      // A panel that only kept the current state would answer "is this
      // account suspended" and never "why was it, and who decided".
      expect(panel.log, hasLength(3));
      expect(
        panel.log.map((entry) => entry.action),
        containsAll([
          AdminAction.reinstateUser,
          AdminAction.suspendUser,
          AdminAction.approveUser,
        ]),
      );
    });

    test('newest first, because that is how a log is read', () async {
      final panel = await admin();
      await panel.approve('a');
      await panel.approve('b');

      expect(panel.log.first.targetUserId, 'b');
    });
  });

  group('an override needs a reason', () {
    test('the rules say which ones', () {
      expect(rules.needsNote(AdminAction.adjustWallet), isTrue);
      expect(rules.needsNote(AdminAction.unlockWallet), isTrue);
      expect(rules.needsNote(AdminAction.suspendUser), isTrue);

      // Approving is the ordinary outcome and needs no defence.
      expect(rules.needsNote(AdminAction.approveUser), isFalse);
    });

    test('and the controller refuses without one', () async {
      // Section 12's own argument: an entry reading "adjusted balance by
      // -4,000" with no reason is exactly the black box the log exists to
      // prevent. So the change does not happen at all.
      final panel = await admin();

      await panel.adjustWallet('user-009', tokens: -4000, note: '');
      expect(panel.log, isEmpty);
      expect(panel.walletOf('user-009').balance, 0);

      await panel.suspend('user-009', note: '  ');
      expect(panel.log, isEmpty);
      expect(panel.reviewOf('user-009').status, ReviewStatus.pending);
    });

    test('a word is enough — this is not an essay', () {
      expect(rules.isUsableNote('fraud'), isTrue);
      expect(rules.isUsableNote('ok'), isFalse);
      expect(rules.isUsableNote(null), isFalse);
    });
  });

  group('unlocking somebody', () {
    test('clears exactly what they owe, as a ledger entry', () async {
      // The wallet has no balance field to overwrite — see Wallet — so an
      // override is one more entry in a history the worker can read, sitting
      // next to the commissions it is putting right.
      final store = await LocalStore.open();
      final wallet = WalletController(store)..setAccount('user-016');

      await wallet.topUp(1000, at: now);
      await wallet.recordCompletion(
        jobId: 'j1',
        agreedFare: 40000,
        at: now,
      );
      await wallet.recordCompletion(
        jobId: 'j2',
        agreedFare: 40000,
        at: now,
      );

      expect(wallet.isLockedOut, isTrue);
      final owed = -wallet.balance;

      final panel = AdminController(store)..load();
      await panel.unlockWallet('user-016', note: 'Charged in error.');

      final after = panel.walletOf('user-016');
      expect(after.balance, 0);
      expect(const WalletRules().isLockedOut(after), isFalse);
      expect(
        after.entries.last.kind,
        WalletEntryKind.adminAdjustment,
        reason: 'the correction must be visible to the worker',
      );
      expect(panel.log.single.tokens, owed);
    });

    test('does nothing to somebody who is not locked', () async {
      final panel = await admin();
      await panel.unlockWallet('user-009', note: 'Just checking.');

      expect(panel.log, isEmpty);
      expect(panel.walletOf('user-009').entries, isEmpty);
    });
  });

  group('the queue', () {
    test('puts flagged accounts first, then oldest', () {
      final queue = rules.queue([
        const AccountReview(userId: 'b'),
        const AccountReview(userId: 'a'),
        const AccountReview(
          userId: 'z',
          verification: Verification(simNameMatches: false),
        ),
        const AccountReview(userId: 'c', status: ReviewStatus.approved),
      ]);

      expect(queue.map((r) => r.userId), ['z', 'a', 'b']);
    });

    test('a SIM mismatch is a flag, never a rejection', () {
      // Section 2 is explicit that false positives are expected — a worker on
      // a family member's SIM is the ordinary case. So the flag changes where
      // they sit in the queue and nothing else.
      const flagged = AccountReview(
        userId: 'z',
        verification: Verification(simNameMatches: false),
      );

      expect(flagged.isFlagged, isTrue);
      expect(flagged.status, ReviewStatus.pending);
      expect(flagged.needsDecision, isTrue);
    });

    test('a suspension can always be undone', () {
      // "Full CRUD scope", and a suspension nobody can reverse is a deletion
      // wearing a softer word.
      const suspended = AccountReview(
        userId: 'z',
        status: ReviewStatus.suspended,
      );

      expect(rules.mayReinstate(suspended), isTrue);
    });
  });

  group('the CNIC shape check', () {
    test('accepts thirteen digits, and nothing else', () {
      expect(rules.isPlausibleCnic('35202-1234567-1'), isTrue);

      // Punctuation is not the check. A keypad has no dash, and refusing
      // thirteen correct digits over one is how a worker gets stuck on the
      // first screen of verification. P1-9 moved this to `VerificationRules`,
      // where the worker's own side of Section 2 lives, and it normalises
      // before it matches — this delegates so the two cannot drift.
      expect(rules.isPlausibleCnic('3520212345671'), isTrue);

      expect(rules.isPlausibleCnic('35202-123456-1'), isFalse);
      expect(rules.isPlausibleCnic('abcde-1234567-1'), isFalse);
      expect(rules.isPlausibleCnic(null), isFalse);
    });
  });

  group('the seeded panel', () {
    test('has a queue to work through, including a flagged account', () async {
      final panel = await seededAdmin();

      expect(panel.queue, isNotEmpty);
      expect(panel.queue.any((review) => review.isFlagged), isTrue);
    });

    test('has open disputes, and they name real people', () async {
      final panel = await seededAdmin();

      expect(panel.openDisputes, isNotEmpty);
      for (final dispute in panel.openDisputes) {
        expect(dispute.aboutUserId, isNot(dispute.raisedByUserId));
        expect(panel.mayOpenCnic(dispute.aboutUserId), isTrue);
      }
    });

    test('but starts with an empty log', () async {
      // It records what staff did. Seeding it would be the one place in the
      // demo where the data is a lie about a person rather than a plausible
      // example of one.
      final panel = await seededAdmin();
      expect(panel.log, isEmpty);
    });

    test('and only staff can reach it', () async {
      final staff = DemoAccounts.byId(DemoAccounts.staffId);

      expect(staff.isAdmin, isTrue);
      expect(staff.isSeeded, isFalse);

      for (final account in DemoAccounts.roster) {
        if (account.id == DemoAccounts.staffId) continue;
        expect(account.isAdmin, isFalse, reason: account.id);
      }
    });
  });
}
