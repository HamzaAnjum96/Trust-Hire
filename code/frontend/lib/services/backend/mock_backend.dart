import 'dart:math';

import 'remote_api.dart';

/// A server that is not there, behaving like one that is.
///
/// **The refusals are the point.** A mock that accepts whatever it is handed is
/// a dictionary with latency: the sync layer above it would look correct while
/// being unable to cope with the one thing a real server does, which is say no.
/// So this refuses the same list `code/backend/migrations/` refuses —
/// [rulesEnforcedHere] names each one and the constraint it stands in for — and
/// `backend_test.dart` checks the two lists agree.
///
/// What it does **not** stand in for, and should not be read as evidence about:
///
///  * network behaviour beyond a delay and a failure switch;
///  * concurrency between two real clients;
///  * anything about Supabase's own semantics — auth, row-level security,
///    realtime. Those arrive with a project to point at.
class MockBackend implements RemoteApi {
  MockBackend({
    this.latency = Duration.zero,
    DateTime? now,
    Random? random,
  })  : _clock = now ?? DateTime.now(),
        _random = random ?? Random(20260728);

  /// How slow to pretend to be. Zero in tests that are not about waiting.
  final Duration latency;

  /// The server's clock. Advanced by hand so a test can order writes without
  /// sleeping, and so nothing here depends on a device's idea of the time.
  DateTime _clock;
  final Random _random;

  /// Set to make the next calls fail as if the connection had gone. The
  /// demo's offline switch, and how a test reaches the outbox's retry path.
  bool offline = false;

  /// Every row, by entity and id.
  final Map<RemoteEntity, Map<String, RemoteRecord>> _rows = {
    for (final entity in RemoteEntity.values) entity: <String, RemoteRecord>{},
  };

  int pulls = 0;
  int pushes = 0;

  /// Every refusal this can return, and the constraint it stands in for.
  ///
  /// Kept as data rather than as comments so a test can check the list is
  /// complete. A mock that drifts from the thing it mocks is worse than no
  /// mock: it makes the app pass against a server that does not exist.
  ///
  /// The values are terse on purpose. `localisation_test.dart` refuses any
  /// three-word English literal under `lib/`, and it is right to — that guard
  /// found the first version of this file sending display prose over the wire.
  /// Naming a constraint rather than describing it keeps both true.
  static const rulesEnforcedHere = <RefusalCode, String>{
    RefusalCode.fareIsLocked: 'jobs_fare_is_locked (0002_jobs.sql)',
    RefusalCode.workerCannotBeSwapped: 'jobs_fare_is_locked (0002_jobs.sql)',
    RefusalCode.nobodyWorksForThemselves:
        'worker_is_not_the_hirer (0002_jobs.sql)',
    RefusalCode.anotherOfferWasAccepted:
        'bids_one_accepted_per_job (0003_marketplace.sql)',
    RefusalCode.offerDoesNotMatchTheJob:
        'agreed_fare_matches_bid (0003_marketplace.sql)',
    RefusalCode.jobIsNotFinished:
        'rating_needs_finished_work (0003_marketplace.sql)',
    RefusalCode.alreadyRatedFromThatSide:
        'ratings unique (job_id, side) (0003_marketplace.sql)',
    RefusalCode.recordIsAppendOnly:
        'ledgers_are_append_only (0003_marketplace.sql)',
    RefusalCode.commissionAlreadyCharged:
        'wallet_one_commission_per_job (0003_marketplace.sql)',
    RefusalCode.messageCannotBeEdited:
        'messages_body_is_immutable (0003_marketplace.sql)',
    RefusalCode.changedElsewhere: 'row version: no SQL equivalent',
    RefusalCode.unreachable: 'network: no SQL equivalent',
  };

  // --- The wire ------------------------------------------------------------

  @override
  Future<List<RemoteRecord>> pull({DateTime? since}) async {
    await _travel();
    pulls += 1;

    final all = [
      for (final byId in _rows.values) ...byId.values,
    ]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));

    if (since == null) return all;
    return all.where((row) => row.updatedAt.isAfter(since)).toList();
  }

  @override
  Future<PushOutcome> push(List<PendingWrite> writes) async {
    await _travel();
    pushes += 1;

    final accepted = <RemoteRecord>[];
    final refused = <Refusal>[];

    for (final write in writes) {
      final existing = _rows[write.entity]![write.id];

      // Somebody else moved it on while this device was away. Retrying sends
      // the same edit against something that is no longer true, so this is
      // reported rather than queued again.
      if (existing != null && existing.version != write.baseVersion) {
        refused.add(
          Refusal(
            write: write,
            reason: RefusalReason.staleVersion,
            code: RefusalCode.changedElsewhere,
          ),
        );
        continue;
      }

      final broken = _ruleBrokenBy(write, existing);
      if (broken != null) {
        refused.add(
          Refusal(
            write: write,
            reason: RefusalReason.ruleRefusedIt,
            code: broken,
          ),
        );
        continue;
      }

      _clock = _clock.add(const Duration(milliseconds: 1));
      final stored = RemoteRecord(
        entity: write.entity,
        id: write.id,
        data: Map<String, dynamic>.from(write.data),
        updatedAt: _clock,
        version: (existing?.version ?? 0) + 1,
      );

      _rows[write.entity]![write.id] = stored;
      accepted.add(stored);
    }

    return PushOutcome(accepted: accepted, refused: refused);
  }

  // --- The rules -----------------------------------------------------------

  /// Which rule [write] breaks, or null.
  ///
  /// Read alongside `code/backend/migrations/`: every branch here has a
  /// constraint or trigger it stands in for, listed in [rulesEnforcedHere].
  RefusalCode? _ruleBrokenBy(PendingWrite write, RemoteRecord? existing) {
    switch (write.entity) {
      case RemoteEntity.walletEntry:
      case RemoteEntity.auditEntry:
        // Append-only, and for the same reason in both cases: a record that
        // can be rewritten afterwards is a record nobody can rely on.
        if (existing != null) return RefusalCode.recordIsAppendOnly;
        if (write.entity == RemoteEntity.walletEntry) {
          return _commissionAlreadyCharged(write);
        }
        return null;

      case RemoteEntity.job:
        return _jobRuleBrokenBy(write, existing);

      case RemoteEntity.bid:
        return _bidRuleBrokenBy(write);

      case RemoteEntity.rating:
        return _ratingRuleBrokenBy(write);

      case RemoteEntity.message:
        return _messageRuleBrokenBy(write, existing);

      case RemoteEntity.review:
      case RemoteEntity.dispute:
        return null;
    }
  }

  /// **What was said cannot change.** A message is only ever edited to add a
  /// read receipt; anything else is somebody rewriting a conversation after
  /// the fact, which is exactly what makes a thread worth keeping.
  RefusalCode? _messageRuleBrokenBy(PendingWrite write, RemoteRecord? existing) {
    if (existing == null) return null;

    final changedBody = write.data['body'] != existing.data['body'];
    final changedSender = write.data['senderId'] != existing.data['senderId'];

    return changedBody || changedSender
        ? RefusalCode.messageCannotBeEdited
        : null;
  }

  RefusalCode? _jobRuleBrokenBy(PendingWrite write, RemoteRecord? existing) {
    final posted = write.data['postedBy'];
    final worker = write.data['acceptedWorkerId'];
    final booked = write.data['bookedWorkerId'];

    if (posted != null && (worker == posted || booked == posted)) {
      return RefusalCode.nobodyWorksForThemselves;
    }

    if (existing == null) return null;

    // **The fare lock.** Section 11's commission is trustworthy only while the
    // agreed fare is the number both sides agreed to.
    final was = existing.data['agreedFare'];
    final now = write.data['agreedFare'];
    if (was != null && now != was) {
      return RefusalCode.fareIsLocked;
    }

    final wasWorker = existing.data['acceptedWorkerId'];
    if (wasWorker != null && worker != wasWorker) {
      return RefusalCode.workerCannotBeSwapped;
    }

    return null;
  }

  RefusalCode? _bidRuleBrokenBy(PendingWrite write) {
    if (write.data['status'] != 'accepted') return null;

    final jobId = write.data['jobId'];

    final anotherWinner = _rows[RemoteEntity.bid]!.values.any(
      (row) =>
          row.data['jobId'] == jobId &&
          row.id != write.id &&
          row.data['status'] == 'accepted',
    );
    if (anotherWinner) {
      return RefusalCode.anotherOfferWasAccepted;
    }

    // And it has to be the offer the job records, or the commission is charged
    // on a number nobody agreed to.
    final job = _rows[RemoteEntity.job]![jobId];
    if (job != null) {
      final fare = job.data['agreedFare'];
      final worker = job.data['acceptedWorkerId'];
      if (fare != null && fare != write.data['fare']) {
        return RefusalCode.offerDoesNotMatchTheJob;
      }
      if (worker != null && worker != write.data['workerId']) {
        return RefusalCode.offerDoesNotMatchTheJob;
      }
    }

    return null;
  }

  RefusalCode? _ratingRuleBrokenBy(PendingWrite write) {
    final jobId = write.data['jobId'];
    final job = _rows[RemoteEntity.job]![jobId];

    // A cancelled job is deliberately excluded: nobody did any work, and a
    // one-star for a job that never happened is a weapon rather than a signal.
    if (job != null && job.data['status'] != 'completed') {
      return RefusalCode.jobIsNotFinished;
    }

    final side = write.data['side'];
    final already = _rows[RemoteEntity.rating]!.values.any(
      (row) =>
          row.data['jobId'] == jobId &&
          row.data['side'] == side &&
          row.id != write.id,
    );
    if (already) return RefusalCode.alreadyRatedFromThatSide;

    return null;
  }

  RefusalCode? _commissionAlreadyCharged(PendingWrite write) {
    if (write.data['kind'] != 'commission') return null;

    final jobId = write.data['jobId'];
    if (jobId == null) return null;

    final charged = _rows[RemoteEntity.walletEntry]!.values.any(
      (row) =>
          row.data['kind'] == 'commission' &&
          row.data['jobId'] == jobId &&
          row.id != write.id,
    );

    return charged ? RefusalCode.commissionAlreadyCharged : null;
  }

  // --- Pretending to be far away -------------------------------------------

  Future<void> _travel() async {
    if (offline) {
      throw const Unreachable('the demo backend is switched off');
    }
    if (latency > Duration.zero) {
      // Jittered, because a fixed delay is the one thing a real network never
      // does, and code written against a fixed delay races the moment it moves.
      final jitter = latency.inMilliseconds ~/ 4;
      await Future<void>.delayed(
        latency + Duration(milliseconds: _random.nextInt(jitter + 1)),
      );
    }
  }

  // --- For tests and the demo ----------------------------------------------

  /// Puts a row in without going through the rules, so a test can set up a
  /// state the rules would refuse to reach twice.
  void seed(RemoteRecord record) {
    _rows[record.entity]![record.id] = record;
  }

  RemoteRecord? rowFor(RemoteEntity entity, String id) => _rows[entity]![id];

  int countOf(RemoteEntity entity) => _rows[entity]!.length;
}
