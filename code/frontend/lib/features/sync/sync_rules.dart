import '../../services/backend/remote_api.dart';

/// What happens when two copies of something disagree.
///
/// Pure functions over plain data, like every rules class before it. The
/// decisions here are the whole of P1-8b that is worth arguing about: the
/// transport is plumbing, but "whose version of this job is right" is a product
/// question with a wrong answer that loses somebody's work.
///
/// **The premise is that the app is offline-first.** People using Trust Hire
/// lose signal in the middle of a job — that is the setting, not an edge case —
/// so a local write must land locally and immediately, and reconcile later.
/// Every rule below follows from that.
class SyncRules {
  const SyncRules();

  /// How long a write may sit unsent before the app says so.
  ///
  /// Not a timeout — nothing is thrown away. It is when "waiting to sync"
  /// stops being reassuring and starts being something the person should know
  /// about, because they may be about to walk away from a job believing it was
  /// marked finished.
  static const quietFor = Duration(minutes: 10);

  /// How many times a temporary failure is retried before it is reported.
  ///
  /// Retrying forever is not persistence, it is a queue that never drains and
  /// nobody looks at.
  static const maxAttempts = 8;

  /// Whether [local] should replace [remote].
  ///
  /// **The server wins whenever the schema locks the field.** An agreed fare,
  /// a chosen worker and a finished status are all written once; if the server
  /// already has one, a local edit made offline against an older version is
  /// working from something that is no longer true, however recent it is.
  ///
  /// Everything else is last-write-wins on the *server's* clock. A device's
  /// clock is somebody's phone, and phones are wrong — often by more than the
  /// gap between two edits.
  bool localWins(RemoteRecord remote, PendingWrite local) {
    if (remote.entity.isAppendOnly) return false;
    if (local.baseVersion != remote.version) return false;

    return true;
  }

  /// Merging a row the server has with one this device has.
  ///
  /// Append-only kinds are a union by id and cannot conflict: two devices
  /// adding ledger entries produce both, which is the correct answer rather
  /// than a lucky one. Everything else takes the server's copy, because the
  /// server is where the rules ran.
  Map<String, dynamic> merge({
    required RemoteRecord remote,
    Map<String, dynamic>? local,
  }) {
    if (local == null) return remote.data;
    if (remote.entity.isAppendOnly) return remote.data;

    return remote.data;
  }

  /// What the outbox should do with a refusal.
  ///
  /// Three answers, and getting them the same would be the bug: a permanent
  /// refusal kept in the queue blocks everything behind it forever, and a
  /// temporary one dropped loses the person's work silently.
  OutboxDecision decide(Refusal refusal) {
    if (!refusal.isWorthRetrying) return OutboxDecision.reportAndDrop;

    if (refusal.write.attempts + 1 >= maxAttempts) {
      return OutboxDecision.reportAndKeep;
    }

    return OutboxDecision.retry;
  }

  /// Whether a queue this old is worth mentioning on screen.
  bool shouldWarnAbout(List<PendingWrite> outbox, {required DateTime now}) {
    if (outbox.isEmpty) return false;

    final oldest = outbox
        .map((write) => write.madeAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    return now.difference(oldest) >= quietFor;
  }

  /// The order writes are offered in.
  ///
  /// **Oldest first, and never reordered by kind.** Accepting an offer and
  /// locking a job's fare are two writes that make sense in one sequence only;
  /// a queue that sent all the jobs and then all the bids would offer the
  /// server a job whose fare has no bid behind it, and the server would be
  /// right to refuse it.
  List<PendingWrite> order(Iterable<PendingWrite> outbox) {
    final ordered = outbox.toList()
      ..sort((a, b) => a.madeAt.compareTo(b.madeAt));
    return ordered;
  }
}

/// What to do with a write the server would not take.
enum OutboxDecision {
  /// Temporary. Send it again.
  retry,

  /// Permanent. It will be refused identically forever, so it must leave the
  /// queue — and the person has to be told, because they believe it happened.
  reportAndDrop,

  /// Temporary, but it has been tried enough times that something is wrong.
  /// Kept, so nothing is lost, and surfaced.
  reportAndKeep,
}
