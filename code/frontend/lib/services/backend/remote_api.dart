/// What the app would say to a server, and what a server would say back.
///
/// **There is no server.** P1-8b was planned as "point the repositories at
/// Supabase", and there is nothing to point them at — so what this defines is
/// the *seam*, and [MockBackend] is a stand-in that behaves like the real one
/// in the ways that matter. Swapping in a Supabase client means implementing
/// [RemoteApi] and nothing above this file changes.
///
/// Two decisions shape everything here.
///
/// **The app stays offline-first.** Local storage remains the store of record;
/// this mirrors to and from it. That is not a limitation of the mock — it is
/// what the product needs anyway, because the people it is for lose signal in
/// the middle of a job. A design where the network is the source of truth
/// would have to be undone later.
///
/// **The server refuses things, and a refusal is final.** The whole argument of
/// `code/backend/migrations/` is that rules a client enforces are rules until
/// somebody writes a different client. A mock that accepts whatever it is given
/// would be a dictionary with latency, and would quietly make the sync layer
/// look correct when it is not — so [MockBackend] refuses the same list the SQL
/// schema refuses.
library;

/// The kinds of thing that travel.
///
/// Deliberately the same split as the migrations, so a record's kind names the
/// table it would land in.
enum RemoteEntity {
  job,
  bid,
  rating,

  /// Append-only. See [isAppendOnly].
  walletEntry,

  review,
  dispute,

  /// Append-only, and the one whose whole value is that it cannot be edited.
  auditEntry;

  String get id => name;

  static RemoteEntity fromId(String? id) => RemoteEntity.values.firstWhere(
    (entity) => entity.id == id,
    orElse: () => job,
  );

  /// Whether rows of this kind are only ever added.
  ///
  /// The ledger and the audit log. Nothing merges these and nothing conflicts:
  /// two devices adding entries produce the union, which is the correct answer
  /// rather than a lucky one.
  bool get isAppendOnly =>
      this == RemoteEntity.walletEntry || this == RemoteEntity.auditEntry;
}

/// A row as the server holds it.
class RemoteRecord {
  const RemoteRecord({
    required this.entity,
    required this.id,
    required this.data,
    required this.updatedAt,
    required this.version,
  });

  final RemoteEntity entity;
  final String id;
  final Map<String, dynamic> data;

  /// Assigned by the server, never by the client.
  ///
  /// A client clock is somebody's phone, and phones are wrong. Ordering writes
  /// by a device's idea of the time is how the later of two edits loses.
  final DateTime updatedAt;

  /// Increments on every accepted write. What a client sends back to say
  /// "I am editing the version I last saw".
  final int version;

  RemoteRecord copyWith({
    Map<String, dynamic>? data,
    DateTime? updatedAt,
    int? version,
  }) => RemoteRecord(
    entity: entity,
    id: id,
    data: data ?? this.data,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'entity': entity.id,
    'id': id,
    'data': data,
    'updatedAt': updatedAt.toIso8601String(),
    'version': version,
  };

  factory RemoteRecord.fromJson(Map<String, dynamic> json) => RemoteRecord(
    entity: RemoteEntity.fromId(json['entity'] as String?),
    id: json['id'] as String,
    data: (json['data'] as Map).cast<String, dynamic>(),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    version: json['version'] as int? ?? 0,
  );
}

/// A write the app made locally and has not yet had accepted.
class PendingWrite {
  const PendingWrite({
    required this.entity,
    required this.id,
    required this.data,
    required this.madeAt,
    this.baseVersion = 0,
    this.attempts = 0,
  });

  final RemoteEntity entity;
  final String id;
  final Map<String, dynamic> data;

  /// When the person did it, by their clock. Used for ordering the outbox and
  /// for telling them how long something has been waiting — **never** for
  /// deciding which of two writes wins. See [RemoteRecord.updatedAt].
  final DateTime madeAt;

  /// The version this edit was made against. Zero for a row the client
  /// believes is new.
  final int baseVersion;

  final int attempts;

  PendingWrite retried() => PendingWrite(
    entity: entity,
    id: id,
    data: data,
    madeAt: madeAt,
    baseVersion: baseVersion,
    attempts: attempts + 1,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'entity': entity.id,
    'id': id,
    'data': data,
    'madeAt': madeAt.toIso8601String(),
    'baseVersion': baseVersion,
    'attempts': attempts,
  };

  factory PendingWrite.fromJson(Map<String, dynamic> json) => PendingWrite(
    entity: RemoteEntity.fromId(json['entity'] as String?),
    id: json['id'] as String,
    data: (json['data'] as Map).cast<String, dynamic>(),
    madeAt: DateTime.parse(json['madeAt'] as String),
    baseVersion: json['baseVersion'] as int? ?? 0,
    attempts: json['attempts'] as int? ?? 0,
  );
}

/// Why a write was refused.
///
/// A closed list, because "the server said no" is not something a screen can
/// act on. Each of these has a different right answer: one is worth retrying,
/// two are worth telling the person about, and one is a bug.
enum RefusalReason {
  /// The row moved on while this device was offline — somebody else edited the
  /// version this write was made against.
  ///
  /// Retrying is *not* the answer. The edit was made against something that is
  /// no longer true.
  staleVersion,

  /// A rule refused it: the fare lock, a second accepted bid, an edit to a
  /// ledger entry. **Final.** The same write will be refused forever, so the
  /// outbox must stop carrying it.
  ruleRefusedIt,

  /// The connection failed. Nothing was decided. Retry.
  unreachable,
}

/// Which rule said no.
///
/// **A code rather than a sentence.** A server sending display prose decides
/// what language the app speaks, and this one speaks two — so the wire carries
/// the reason and the screen carries the wording. `localisation_test.dart`
/// caught the first version of this doing it the other way round.
enum RefusalCode {
  fareIsLocked,
  workerCannotBeSwapped,
  nobodyWorksForThemselves,
  anotherOfferWasAccepted,
  offerDoesNotMatchTheJob,
  recordIsAppendOnly,
  commissionAlreadyCharged,
  jobIsNotFinished,
  alreadyRatedFromThatSide,

  /// Somebody else moved the row on while this device was away.
  changedElsewhere,

  /// The connection failed. Nothing was decided.
  unreachable;

  String get id => name;
}

/// A write that did not land, and what to do about it.
class Refusal {
  const Refusal({
    required this.write,
    required this.reason,
    required this.code,
  });

  final PendingWrite write;
  final RefusalReason reason;

  /// Which rule. The screen turns this into words — see [RefusalCode].
  final RefusalCode code;

  /// Whether sending the same thing again could ever succeed.
  ///
  /// **The property the outbox turns on.** A write that can never land must
  /// leave the queue and be surfaced; one that can must stay. Retrying a
  /// permanent refusal forever is how a queue silently stops delivering
  /// anything behind it.
  bool get isWorthRetrying => reason == RefusalReason.unreachable;
}

/// What came back from a push.
class PushOutcome {
  const PushOutcome({this.accepted = const [], this.refused = const []});

  final List<RemoteRecord> accepted;
  final List<Refusal> refused;

  bool get isCompleteSuccess => refused.isEmpty;
}

/// The server, as far as the app is concerned.
abstract class RemoteApi {
  /// Everything changed since [since], or everything when null.
  Future<List<RemoteRecord>> pull({DateTime? since});

  /// Offers [writes] in order. Returns what landed and what did not.
  ///
  /// Order matters: accepting a bid and locking a job's fare are two writes
  /// that only make sense in one sequence, and a server that applied them in
  /// any order would produce a job whose fare has no bid behind it.
  Future<PushOutcome> push(List<PendingWrite> writes);
}

/// Where a repository hands a local write on to the outbox.
///
/// A function rather than an interface so a repository depends on nothing: it
/// writes locally, calls this, and is finished. **The call must never be
/// awaited on the critical path in a way that can fail** — a person on a bus
/// with no signal is the ordinary case, and a save that waits for a network is
/// a save that does not happen.
typedef QueueWrite = Future<void> Function(PendingWrite write);

/// Thrown when the network is not there.
///
/// Its own type rather than a generic exception, because "unreachable" is the
/// one failure the outbox treats as temporary, and catching everything would
/// make a permanent refusal look retryable.
class Unreachable implements Exception {
  const Unreachable([this.detail]);

  final String? detail;

  @override
  String toString() => 'Unreachable${detail == null ? '' : ': $detail'}';
}
