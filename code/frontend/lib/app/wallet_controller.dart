import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../features/wallet/stripe_return.dart';
import '../features/wallet/wallet_rules.dart';
import '../models/account.dart';
import '../models/job.dart';
import '../models/wallet.dart';
import '../services/local_store.dart';

/// Holds the wallet and appends to its ledger.
///
/// Every method here follows the same shape: ask [WalletRules] what happened,
/// append those entries, save. Nothing computes a balance, because nothing
/// stores one — see [Wallet].
class WalletController extends ChangeNotifier {
  WalletController(this._store, {this.rules = const WalletRules()});

  final LocalStore _store;
  final WalletRules rules;

  /// Whose wallet this is. One ledger per demo account, because a commission
  /// is charged to the person who did the work — handing a hirer the worker's
  /// balance would make the switch meaningless.
  String _workerId = DemoAccounts.deviceId;
  String get workerId => _workerId;

  /// Points the controller at another account's ledger and reads it.
  ///
  /// The old ledger is not written back: every change is saved as it happens,
  /// so there is never an unsaved balance to lose.
  void setAccount(String id) {
    if (_workerId == id) return;
    _workerId = id;
    _wallet = Wallet(userId: id);
    load();
  }

  String get _key => StoreKeys.forAccount(StoreKeys.wallet, _workerId);

  Wallet _wallet = Wallet(userId: DemoAccounts.deviceId);
  Wallet get wallet => _wallet;

  int get balance => _wallet.balance;
  bool get isLockedOut => rules.isLockedOut(_wallet);
  bool get canTakeWork => rules.canTakeWork(_wallet);
  bool get isInDebt => _wallet.balance < 0;

  void load() {
    final raw = _store.readString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        _wallet = Wallet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on FormatException {
        // A corrupt ledger is not recoverable by guessing. Starting empty is
        // wrong in the worker's favour, which is the right direction to be
        // wrong in when the alternative is inventing a debt.
        _wallet = Wallet(userId: _workerId);
      }
    } else {
      _wallet = Wallet(userId: _workerId);
    }

    notifyListeners();
  }

  /// The commission and any first-job credit for a finished job.
  ///
  /// [listedFare] is set only for a Mode B booking, where the commission is
  /// half the usual rate — the platform funds the hirer's discount out of its
  /// own take. See [PremiumRules.hirerDiscountTenthsPercent].
  ///
  /// Idempotent by job: a completion that gets recorded twice — a retry, a
  /// double tap — must not charge twice.
  Future<void> recordCompletion({
    required String jobId,
    required int agreedFare,
    int? listedFare,
    DateTime? at,
  }) async {
    if (_hasEntryFor(jobId, WalletEntryKind.commission)) return;

    await _append(
      rules.onJobCompleted(
        wallet: _wallet,
        jobId: jobId,
        agreedFare: agreedFare,
        listedFare: listedFare,
        now: at ?? DateTime.now(),
      ),
    );
  }

  /// The same, for a job you already have.
  Future<void> recordCompletionOf(Job job, {DateTime? at}) =>
      recordCompletion(
        jobId: job.id,
        agreedFare: job.agreedFare ?? 0,
        listedFare: job.listedFare,
        at: at,
      );

  /// The penalty for accepting a job and then walking away.
  Future<void> recordWorkerCancellation({
    required String jobId,
    DateTime? at,
  }) async {
    if (_hasEntryFor(jobId, WalletEntryKind.cancellationPenalty)) return;

    await _append(
      rules.onWorkerCancelled(jobId: jobId, now: at ?? DateTime.now()),
    );
  }

  /// Buys tokens. Simulated — Section 13a excludes real payment handling.
  Future<void> topUp(int tokens, {DateTime? at}) async {
    await _append(
      rules.onTopUp(wallet: _wallet, tokens: tokens, now: at ?? DateTime.now()),
    );
  }

  /// Whether [paymentId] has already been turned into tokens here.
  bool hasCredited(String paymentId) =>
      _wallet.entries.any((e) => e.paymentId == paymentId);

  /// Credits a Stripe payment.
  ///
  /// **Idempotent by payment**, exactly as a commission is by job: a return
  /// page reloaded before its address was tidied, two tabs handling the same
  /// return — each of those is the same payment, which buys tokens once.
  /// Returns false when it had already been credited.
  ///
  /// [tokens] must be what the payment was for — never a number somebody
  /// could have changed on the way.
  Future<bool> creditPayment({
    required String paymentId,
    required int tokens,
    DateTime? at,
  }) async {
    if (paymentId.isEmpty || hasCredited(paymentId)) return false;

    await _append(
      rules.onTopUp(
        wallet: _wallet,
        tokens: tokens,
        now: at ?? DateTime.now(),
        paymentId: paymentId,
      ),
    );
    return true;
  }

  /// About to leave for a Stripe Payment Link: remember who is buying how
  /// much, so the page Stripe sends back can tell a return it started from
  /// one that was typed in. Replaces any earlier one — only the latest top-up
  /// is the one somebody is in the middle of.
  Future<void> notePendingTopUp(int tokens, {DateTime? at}) =>
      _store.writeString(
        StoreKeys.pendingTopUp,
        jsonEncode(
          PendingTopUp(
            account: _workerId,
            tokens: tokens,
            startedAt: at ?? DateTime.now(),
          ).toJson(),
        ),
      );

  PendingTopUp? get pendingTopUp {
    final raw = _store.readString(StoreKeys.pendingTopUp);
    if (raw == null || raw.isEmpty) return null;
    try {
      return PendingTopUp.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Unreadable is the same as absent: nothing gets credited on its say.
      return null;
    }
  }

  /// Credits a return from a Stripe Payment Link, if this browser started it.
  ///
  /// The pending top-up is cleared only *after* the credit is written. A page
  /// closed between the two leaves it in place, and a reload then finds the
  /// session already in the ledger — [creditPayment] is idempotent on it — so
  /// the order costs nothing and the other order could lose a payment.
  Future<StripeReturnOutcome> completeStripeReturn(
    StripeReturn returned, {
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    final verdict = returned.check(pendingTopUp, account: _workerId, now: now);
    if (verdict != StripeReturnOutcome.credited) return verdict;

    final fresh = await creditPayment(
      paymentId: returned.sessionId,
      tokens: returned.tokens,
      at: now,
    );
    await _store.remove(StoreKeys.pendingTopUp);
    return fresh
        ? StripeReturnOutcome.credited
        : StripeReturnOutcome.alreadyCredited;
  }

  bool _hasEntryFor(String jobId, WalletEntryKind kind) =>
      _wallet.entries.any((e) => e.jobId == jobId && e.kind == kind);

  Future<void> _append(List<WalletEntry> entries) async {
    if (entries.isEmpty) return;

    _wallet = _wallet.withEntries(entries);
    notifyListeners();

    await _store.writeString(_key, jsonEncode(_wallet.toJson()));
  }
}
