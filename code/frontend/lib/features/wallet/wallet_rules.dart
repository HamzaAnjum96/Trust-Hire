import 'package:uuid/uuid.dart';

import '../../models/wallet.dart';

/// Section 11, as arithmetic.
///
/// Every method here returns *entries to append* rather than a changed wallet.
/// The wallet derives everything from its ledger, so the only way to change it
/// is to record what happened — which means there is no path that moves a
/// balance without leaving a reason behind.
class WalletRules {
  const WalletRules({this.uuid = const Uuid()});

  final Uuid uuid;

  /// 5% of the agreed fare, on completion.
  static const commissionPercent = 5;

  /// What a new worker gets toward their first job's commission.
  static const firstJobCreditTokens = 500;

  /// Every time lifetime top-up crosses another one of these, a bonus lands.
  static const loyaltyStepTokens = 100000;
  static const loyaltyBonusTokens = 1000;

  /// Charged when a worker accepts a job and then walks away.
  ///
  /// Section 11 says "a small token penalty" without naming one. Rs. 200 is
  /// chosen to be felt but not punitive: enough that accepting casually and
  /// dropping out has a cost, small enough that a worker with a real problem
  /// — illness, a family emergency — is not pushed into going anyway. It is
  /// flat rather than a share of the fare, so cancelling a large job is not
  /// disproportionately worse than cancelling a small one; the harm to the
  /// hirer is much the same either way.
  static const cancellationPenaltyTokens = 200;

  /// The platform's cut of a fare, rounded to whole tokens.
  ///
  /// Rounds down. At 5% the difference is at most a rupee, and it should fall
  /// in favour of the person being charged.
  int commissionOn(int agreedFare) => (agreedFare * commissionPercent) ~/ 100;

  /// What to record when a job completes.
  ///
  /// The credit is a separate entry from the commission rather than a
  /// discount applied to it, so the worker's history shows both the full 5%
  /// they were charged and the help they were given. Netting them would hide
  /// the commission behind a smaller number and make the ledger useless as an
  /// explanation.
  List<WalletEntry> onJobCompleted({
    required Wallet wallet,
    required String jobId,
    required int agreedFare,
    required DateTime now,
  }) {
    final commission = commissionOn(agreedFare);
    if (commission <= 0) return const [];

    final entries = <WalletEntry>[
      WalletEntry(
        id: uuid.v4(),
        kind: WalletEntryKind.commission,
        tokens: -commission,
        createdAt: now,
        jobId: jobId,
      ),
    ];

    if (!wallet.hasFirstJobCredit) {
      // Capped at the commission owed: the credit is *toward* a commission,
      // not a gift of 500 tokens. A worker whose first job owes Rs. 80 gets
      // Rs. 80 of help, and the rest is not carried forward — Section 11 ties
      // it to the first job specifically.
      final credit = commission < firstJobCreditTokens
          ? commission
          : firstJobCreditTokens;

      entries.add(
        WalletEntry(
          id: uuid.v4(),
          kind: WalletEntryKind.firstJobCredit,
          tokens: credit,
          createdAt: now,
          jobId: jobId,
        ),
      );
    }

    return entries;
  }

  /// What to record when a worker buys tokens, including any bonus it earns.
  List<WalletEntry> onTopUp({
    required Wallet wallet,
    required int tokens,
    required DateTime now,
  }) {
    if (tokens <= 0) return const [];

    final entries = <WalletEntry>[
      WalletEntry(
        id: uuid.v4(),
        kind: WalletEntryKind.topUp,
        tokens: tokens,
        createdAt: now,
      ),
    ];

    return [
      ...entries,
      ...loyaltyBonusesDue(wallet.withEntries(entries), now: now),
    ];
  }

  /// Bonuses this wallet has earned and not yet been paid.
  ///
  /// Computed from the totals rather than triggered at the moment of a
  /// crossing, so a bonus cannot be missed by a top-up that failed to write,
  /// nor paid twice by one that wrote twice. A worker who somehow jumps from
  /// Rs. 50,000 to Rs. 250,000 in one payment is owed two.
  List<WalletEntry> loyaltyBonusesDue(Wallet wallet, {required DateTime now}) {
    final earned = wallet.lifetimeTopUp ~/ loyaltyStepTokens;
    final owed = earned - wallet.loyaltyBonusesGranted;
    if (owed <= 0) return const [];

    return [
      for (var i = 0; i < owed; i++)
        WalletEntry(
          id: uuid.v4(),
          kind: WalletEntryKind.loyaltyBonus,
          tokens: loyaltyBonusTokens,
          createdAt: now,
        ),
    ];
  }

  /// What to record when a worker abandons a job they accepted.
  List<WalletEntry> onWorkerCancelled({
    required String jobId,
    required DateTime now,
  }) {
    return [
      WalletEntry(
        id: uuid.v4(),
        kind: WalletEntryKind.cancellationPenalty,
        tokens: -cancellationPenaltyTokens,
        createdAt: now,
        jobId: jobId,
      ),
    ];
  }

  /// Whether the account is locked out of new leads.
  ///
  /// Section 11: a wallet may be in debt for at most one job. A second unpaid
  /// job on top of that locks it until the balance is cleared.
  bool isLockedOut(Wallet wallet) => wallet.unpaidJobs > 1;

  /// Whether a worker can take on new work.
  ///
  /// Being in debt for one job is explicitly allowed — a worker who cannot
  /// afford the commission is exactly the worker who needs the next job.
  bool canTakeWork(Wallet wallet) => !isLockedOut(wallet);
}
