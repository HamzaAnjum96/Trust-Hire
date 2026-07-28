import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../features/admin/admin_rules.dart';
import '../features/wallet/wallet_rules.dart';
import '../models/admin.dart';
import '../models/wallet.dart';
import '../services/local_store.dart';

/// The admin panel's state, and the one place an override can happen.
///
/// **Nothing here changes anything without writing to the log.** Every
/// mutating method goes through [_perform], which records the entry and then
/// applies the change — so Section 12's requirement that "manual overrides
/// remain traceable rather than being a black box" is structural rather than
/// remembered. There is no path that moves a balance or suspends an account
/// while leaving the log alone, because there is no other path.
///
/// The same shape as the wallet's ledger, and for the same reason: a record
/// that depends on somebody remembering to write it is a record with holes in
/// it exactly where somebody had a reason not to.
class AdminController extends ChangeNotifier {
  AdminController(
    this._store, {
    this.rules = const AdminRules(),
    this.walletRules = const WalletRules(),
    this.uuid = const Uuid(),
  });

  final LocalStore _store;
  final AdminRules rules;
  final WalletRules walletRules;

  @visibleForTesting
  final Uuid uuid;

  List<AuditEntry> _log = const <AuditEntry>[];
  Map<String, AccountReview> _reviews = <String, AccountReview>{};
  Map<String, CnicRecord> _cnics = <String, CnicRecord>{};
  List<Dispute> _disputes = const <Dispute>[];

  /// Who is acting. Set from the active demo account, so the log says which
  /// staff member did a thing rather than "admin".
  String _adminId = 'staff';
  void setAccount(String id) {
    if (_adminId == id) return;
    _adminId = id;
    notifyListeners();
  }

  /// Newest first — an audit log is read from the top.
  List<AuditEntry> get log => _log;

  List<AccountReview> get reviews =>
      _reviews.values.toList(growable: false);

  List<AccountReview> get queue => rules.queue(_reviews.values);

  List<Dispute> get disputes => _disputes;
  List<Dispute> get openDisputes =>
      _disputes.where((dispute) => dispute.isOpen).toList(growable: false);

  AccountReview reviewOf(String userId) =>
      _reviews[userId] ?? AccountReview(userId: userId);

  void load() {
    _log =
        (_store.readCollection(StoreKeys.auditLog) ?? const [])
            .map(AuditEntry.fromJson)
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));

    _reviews = {
      for (final json in _store.readCollection(StoreKeys.accountReviews) ??
          const [])
        (json['userId'] as String): AccountReview.fromJson(json),
    };

    _cnics = {
      for (final json in _store.readCollection(StoreKeys.cnicRecords) ??
          const [])
        (json['userId'] as String): CnicRecord.fromJson(json),
    };

    _disputes = (_store.readCollection(StoreKeys.disputes) ?? const [])
        .map(Dispute.fromJson)
        .toList(growable: false);

    notifyListeners();
  }

  // --- Users ---------------------------------------------------------------

  Future<void> approve(String userId, {String? note}) => _perform(
    action: AdminAction.approveUser,
    targetUserId: userId,
    note: note,
    change: () => _setStatus(userId, ReviewStatus.approved, note),
  );

  Future<void> suspend(String userId, {required String note}) => _perform(
    action: AdminAction.suspendUser,
    targetUserId: userId,
    note: note,
    change: () => _setStatus(userId, ReviewStatus.suspended, note),
  );

  Future<void> reinstate(String userId, {required String note}) => _perform(
    action: AdminAction.reinstateUser,
    targetUserId: userId,
    note: note,
    change: () => _setStatus(userId, ReviewStatus.approved, note),
  );

  // --- The CNIC ------------------------------------------------------------

  bool mayOpenCnic(String userId) =>
      rules.mayOpenCnic(userId, disputes: _disputes);

  /// Pulls up a CNIC, if there is an open dispute that justifies it.
  ///
  /// Returns null when there is not, and **writes nothing** in that case: a
  /// refusal is not an inspection, and logging it as one would put a line in
  /// the record saying somebody looked at a document they never saw.
  Future<CnicRecord?> openCnic(String userId, {required String note}) async {
    if (!mayOpenCnic(userId)) return null;

    final record = _cnics[userId];
    if (record == null) return null;

    await _perform(
      action: AdminAction.viewCnic,
      targetUserId: userId,
      note: note,
      change: () async {},
    );

    return record;
  }

  // --- The wallet ----------------------------------------------------------

  /// Moves somebody's balance by hand.
  ///
  /// Appends to *their* ledger rather than overwriting a number, because the
  /// wallet has no number to overwrite — see [Wallet]. So an override is one
  /// more entry in a history the worker can read, sitting next to the
  /// commissions it is correcting, which is the honest way to do it.
  Future<void> adjustWallet(
    String userId, {
    required int tokens,
    required String note,
    DateTime? at,
  }) async {
    if (tokens == 0) return;

    await _perform(
      action: AdminAction.adjustWallet,
      targetUserId: userId,
      note: note,
      tokens: tokens,
      change: () => _appendToWallet(
        userId,
        WalletEntry(
          id: uuid.v4(),
          kind: WalletEntryKind.adminAdjustment,
          tokens: tokens,
          createdAt: at ?? DateTime.now(),
        ),
      ),
    );
  }

  /// Clears whatever debt is locking somebody out.
  ///
  /// Computed rather than asked for: an admin unlocking an account means "let
  /// them work", and making them work out the exact number first is a way to
  /// get it wrong. It still lands as an ordinary ledger entry.
  Future<void> unlockWallet(
    String userId, {
    required String note,
    DateTime? at,
  }) async {
    final wallet = _walletOf(userId);
    if (!walletRules.isLockedOut(wallet)) return;

    final owed = -wallet.balance;

    await _perform(
      action: AdminAction.unlockWallet,
      targetUserId: userId,
      note: note,
      tokens: owed,
      change: () => _appendToWallet(
        userId,
        WalletEntry(
          id: uuid.v4(),
          kind: WalletEntryKind.adminAdjustment,
          tokens: owed,
          createdAt: at ?? DateTime.now(),
        ),
      ),
    );
  }

  Wallet walletOf(String userId) => _walletOf(userId);

  // --- Disputes ------------------------------------------------------------

  Future<void> closeDispute(String disputeId, {required String note}) =>
      _perform(
        action: AdminAction.closeDispute,
        note: note,
        change: () async {
          _disputes = [
            for (final dispute in _disputes)
              if (dispute.id == disputeId)
                dispute.closed(at: DateTime.now(), resolution: note)
              else
                dispute,
          ];
          await _store.writeCollection(
            StoreKeys.disputes,
            _disputes.map((d) => d.toJson()).toList(growable: false),
          );
        },
      );

  // --- The one way anything changes ---------------------------------------

  /// Records the entry, then applies the change.
  ///
  /// In that order deliberately. If the write of the change fails, the log
  /// carries a line for something that did not happen — which a human reading
  /// it can investigate. The other order loses the line for something that
  /// did, which nobody can investigate because there is nothing to see.
  Future<void> _perform({
    required AdminAction action,
    required Future<void> Function() change,
    String? targetUserId,
    String? targetJobId,
    String? note,
    int? tokens,
  }) async {
    final trimmed = note?.trim();

    // Section 12's own argument, enforced: an override with no reason is the
    // black box the audit log exists to prevent.
    if (rules.needsNote(action) && !rules.isUsableNote(trimmed)) return;

    final entry = AuditEntry(
      id: uuid.v4(),
      action: action,
      adminId: _adminId,
      at: DateTime.now(),
      targetUserId: targetUserId,
      targetJobId: targetJobId,
      note: (trimmed?.isEmpty ?? true) ? null : trimmed,
      tokens: tokens,
    );

    _log = [entry, ..._log];
    notifyListeners();

    await _store.writeCollection(
      StoreKeys.auditLog,
      _log.map((e) => e.toJson()).toList(growable: false),
    );

    await change();
    notifyListeners();
  }

  Future<void> _setStatus(
    String userId,
    ReviewStatus status,
    String? note,
  ) async {
    _reviews = {
      ..._reviews,
      userId: reviewOf(
        userId,
      ).copyWith(status: status, note: note, decidedAt: DateTime.now()),
    };

    await _store.writeCollection(
      StoreKeys.accountReviews,
      _reviews.values.map((r) => r.toJson()).toList(growable: false),
    );
  }

  Wallet _walletOf(String userId) {
    final raw = _store.readString(
      StoreKeys.forAccount(StoreKeys.wallet, userId),
    );
    if (raw == null || raw.isEmpty) return Wallet(userId: userId);

    try {
      return Wallet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return Wallet(userId: userId);
    }
  }

  Future<void> _appendToWallet(String userId, WalletEntry entry) async {
    final updated = _walletOf(userId).withEntries([entry]);

    await _store.writeString(
      StoreKeys.forAccount(StoreKeys.wallet, userId),
      jsonEncode(updated.toJson()),
    );
  }
}
