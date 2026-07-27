import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../features/wallet/wallet_rules.dart';
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

  /// No sign-in yet, so one wallet per device. P1-8 gives it an account.
  static const localWorkerId = 'local-user';

  Wallet _wallet = Wallet(userId: localWorkerId);
  Wallet get wallet => _wallet;

  int get balance => _wallet.balance;
  bool get isLockedOut => rules.isLockedOut(_wallet);
  bool get canTakeWork => rules.canTakeWork(_wallet);
  bool get isInDebt => _wallet.balance < 0;

  void load() {
    final raw = _store.readString(StoreKeys.wallet);
    if (raw != null && raw.isNotEmpty) {
      try {
        _wallet = Wallet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on FormatException {
        // A corrupt ledger is not recoverable by guessing. Starting empty is
        // wrong in the worker's favour, which is the right direction to be
        // wrong in when the alternative is inventing a debt.
        _wallet = Wallet(userId: localWorkerId);
      }
    }

    notifyListeners();
  }

  /// The commission and any first-job credit for a finished job.
  ///
  /// Idempotent by job: a completion that gets recorded twice — a retry, a
  /// double tap — must not charge twice.
  Future<void> recordCompletion({
    required String jobId,
    required int agreedFare,
    DateTime? at,
  }) async {
    if (_hasEntryFor(jobId, WalletEntryKind.commission)) return;

    await _append(
      rules.onJobCompleted(
        wallet: _wallet,
        jobId: jobId,
        agreedFare: agreedFare,
        now: at ?? DateTime.now(),
      ),
    );
  }

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

  bool _hasEntryFor(String jobId, WalletEntryKind kind) =>
      _wallet.entries.any((e) => e.jobId == jobId && e.kind == kind);

  Future<void> _append(List<WalletEntry> entries) async {
    if (entries.isEmpty) return;

    _wallet = _wallet.withEntries(entries);
    notifyListeners();

    await _store.writeString(StoreKeys.wallet, jsonEncode(_wallet.toJson()));
  }
}
