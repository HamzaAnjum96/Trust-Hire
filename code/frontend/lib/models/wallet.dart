import '../l10n/app_localizations.dart';

/// Why tokens moved.
enum WalletEntryKind {
  /// Bought tokens. Simulated — Section 13a excludes real money.
  topUp,

  /// The platform's 5% of an agreed fare, on completion.
  commission,

  /// The Rs. 500 a new worker gets toward their first job's commission.
  firstJobCredit,

  /// 1,000 tokens, every time lifetime top-up crosses another Rs. 100,000.
  loyaltyBonus,

  /// Charged when a worker accepts a job and then walks away.
  cancellationPenalty;

  String get id => name;

  static WalletEntryKind fromId(String? id) =>
      WalletEntryKind.values.firstWhere((k) => k.id == id, orElse: () => topUp);

  String label(AppStrings strings) => switch (this) {
    WalletEntryKind.topUp => strings.walletTopUp,
    WalletEntryKind.commission => strings.walletCommission,
    WalletEntryKind.firstJobCredit => strings.walletFirstJobCredit,
    WalletEntryKind.loyaltyBonus => strings.walletLoyaltyBonus,
    WalletEntryKind.cancellationPenalty => strings.walletCancellationPenalty,
  };
}

/// One movement of tokens.
///
/// Immutable, and never deleted. A wallet is an account of what happened, and
/// an entry that can be edited after the fact is an entry nobody can trust.
class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.kind,
    required this.tokens,
    required this.createdAt,
    this.jobId,
  });

  final String id;
  final WalletEntryKind kind;

  /// Signed: positive adds to the balance, negative takes from it. Whole
  /// tokens, and 1 token is Rs. 1 (Section 11).
  final int tokens;

  final DateTime createdAt;

  /// The job this was for, where there was one.
  final String? jobId;

  factory WalletEntry.fromJson(Map<String, dynamic> json) => WalletEntry(
    id: json['id'] as String,
    kind: WalletEntryKind.fromId(json['kind'] as String?),
    tokens: (json['tokens'] as num).round(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    jobId: json['jobId'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'kind': kind.id,
    'tokens': tokens,
    'createdAt': createdAt.toIso8601String(),
    'jobId': jobId,
  };
}

/// A worker's wallet.
///
/// **The ledger is the only stored state.** Balance, lifetime top-up, debt and
/// the lock are all derived by replaying it, so the sprint's own definition of
/// done — "the wallet cannot reach an inconsistent state" — is structural
/// rather than defended. There is no balance field to disagree with the
/// entries that produced it, and no repair routine to write, because the two
/// can never drift apart.
///
/// It costs a walk of the list on every read. At the volumes one person
/// generates, that is nothing next to being unable to be wrong.
class Wallet {
  Wallet({required this.userId, List<WalletEntry>? entries})
    : entries = List.unmodifiable(
        [...?entries]..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      );

  final String userId;

  /// Oldest first — the order they happened, which is the order they have to
  /// be replayed in for the debt count to mean anything.
  final List<WalletEntry> entries;

  /// Tokens available now. Negative means the worker owes the platform.
  int get balance => entries.fold(0, (sum, entry) => sum + entry.tokens);

  /// Everything ever bought. Drives the loyalty bonus, and never goes down —
  /// spending tokens does not undo having bought them.
  int get lifetimeTopUp => entries
      .where((e) => e.kind == WalletEntryKind.topUp)
      .fold(0, (sum, entry) => sum + entry.tokens);

  bool get hasFirstJobCredit =>
      entries.any((e) => e.kind == WalletEntryKind.firstJobCredit);

  /// How many loyalty bonuses have actually been paid.
  int get loyaltyBonusesGranted =>
      entries.where((e) => e.kind == WalletEntryKind.loyaltyBonus).length;

  /// How many jobs' commissions are currently unpaid.
  ///
  /// Replayed in order rather than inferred from the balance. A commission
  /// counts as unpaid when charging it leaves the wallet short — Section 11's
  /// "a second job goes unpaid **on top of** that" — so a charge that deepens
  /// an existing debt is a second unpaid job, not more of the first one.
  ///
  /// Clearing the balance clears the count. The debt is what is owed now, not
  /// a record of every time the worker has been short.
  int get unpaidJobs {
    var running = 0;
    var unpaid = 0;

    for (final entry in entries) {
      running += entry.tokens;

      if (entry.kind == WalletEntryKind.commission && running < 0) {
        unpaid += 1;
      }
      if (running >= 0) unpaid = 0;
    }

    return unpaid;
  }

  Wallet withEntries(Iterable<WalletEntry> added) =>
      Wallet(userId: userId, entries: [...entries, ...added]);

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    userId: json['userId'] as String,
    entries: (json['entries'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(WalletEntry.fromJson)
        .toList(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'userId': userId,
    'entries': entries.map((e) => e.toJson()).toList(),
  };
}
