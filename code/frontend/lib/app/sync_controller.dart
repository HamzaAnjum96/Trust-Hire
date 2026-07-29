import 'package:flutter/foundation.dart';

import '../features/sync/sync_rules.dart';
import '../services/backend/remote_api.dart';
import '../services/local_store.dart';

/// Where the device stands with the server.
enum SyncState {
  /// Everything local has been accepted.
  settled,

  /// Writes are waiting, and the last attempt did not fail.
  sending,

  /// The connection is not there. Work continues; nothing is lost.
  offline,

  /// Something needs a person: a write the server will never accept, or a
  /// queue that has been stuck long enough to be worth saying so.
  needsAttention,
}

/// The outbox, and the only thing that talks to [RemoteApi].
///
/// **Local storage stays the store of record.** Nothing here blocks a write, and
/// nothing here can lose one: a change is saved locally, queued, and offered to
/// the server afterwards. That is what the product needs regardless of the
/// backend — the people it is for lose signal in the middle of a job — so it is
/// not a concession to the server being a mock.
///
/// What it does **not** do yet, deliberately: it does not apply what it pulls
/// back into the repositories. Pulling is implemented and tested, but wiring it
/// into the controllers means deciding what happens when a demo account's
/// seeded history meets a server's copy of it, and with no server to hold a
/// second copy that decision has nothing to be right about. It waits for a
/// hosted backend, and [SyncRules.merge] is where it will go.
class SyncController extends ChangeNotifier {
  SyncController(this._store, this._api, {this.rules = const SyncRules()});

  final LocalStore _store;
  final RemoteApi _api;
  final SyncRules rules;

  List<PendingWrite> _outbox = const [];
  List<Refusal> _needAttention = const [];
  DateTime? _lastPulledAt;
  bool _wasUnreachable = false;

  /// Writes made locally and not yet accepted, oldest first.
  List<PendingWrite> get outbox => _outbox;

  /// Refusals a person has to see. **Never dropped silently** — each of these
  /// is something somebody believes happened and did not.
  List<Refusal> get needAttention => _needAttention;

  DateTime? get lastPulledAt => _lastPulledAt;

  SyncState state({DateTime? now}) {
    if (_needAttention.isNotEmpty) return SyncState.needsAttention;
    if (rules.shouldWarnAbout(_outbox, now: now ?? DateTime.now())) {
      return SyncState.needsAttention;
    }
    if (_wasUnreachable) return SyncState.offline;
    return _outbox.isEmpty ? SyncState.settled : SyncState.sending;
  }

  void load() {
    _outbox = (_store.readCollection(StoreKeys.outbox) ?? const [])
        .map(PendingWrite.fromJson)
        .toList(growable: false);

    final at = _store.readString(StoreKeys.lastPulledAt);
    _lastPulledAt = at == null || at.isEmpty ? null : DateTime.tryParse(at);

    notifyListeners();
  }

  /// Queues a change. Returns immediately — the caller has already written it
  /// locally and must not be made to wait for a network.
  Future<void> enqueue(PendingWrite write) async {
    _outbox = [..._outbox, write];
    await _saveOutbox();
    notifyListeners();
  }

  /// Offers everything waiting, in order.
  ///
  /// Stops at the first write the server does not take. The queue is ordered
  /// because the writes depend on each other — sending the rest after a gap
  /// would offer the server a job whose accepted bid never arrived.
  Future<void> push() async {
    if (_outbox.isEmpty) return;

    final ordered = rules.order(_outbox);

    final PushOutcome outcome;
    try {
      outcome = await _api.push(ordered);
      _wasUnreachable = false;
    } on Unreachable {
      _wasUnreachable = true;
      _outbox = [for (final write in ordered) write.retried()];
      await _saveOutbox();
      notifyListeners();
      return;
    }

    final landed = {for (final record in outcome.accepted) record.id};
    final remaining = <PendingWrite>[];
    final reported = <Refusal>[];

    for (final refusal in outcome.refused) {
      switch (rules.decide(refusal)) {
        case OutboxDecision.retry:
          remaining.add(refusal.write.retried());
        case OutboxDecision.reportAndKeep:
          remaining.add(refusal.write.retried());
          reported.add(refusal);
        case OutboxDecision.reportAndDrop:
          // Left out of `remaining` on purpose. A write the server will refuse
          // identically forever would sit at the head of the queue and stop
          // everything behind it from ever being sent.
          reported.add(refusal);
      }
    }

    _outbox = [
      for (final write in ordered)
        if (!landed.contains(write.id) &&
            !outcome.refused.any((r) => r.write.id == write.id))
          write,
      ...remaining,
    ];

    _needAttention = [..._needAttention, ...reported];

    await _saveOutbox();
    notifyListeners();
  }

  /// Fetches what changed. See the class comment for why nothing is applied
  /// yet.
  Future<List<RemoteRecord>> pull() async {
    try {
      final records = await _api.pull(since: _lastPulledAt);
      _wasUnreachable = false;

      if (records.isNotEmpty) {
        _lastPulledAt = records.last.updatedAt;
        await _store.writeString(
          StoreKeys.lastPulledAt,
          _lastPulledAt!.toIso8601String(),
        );
      }

      notifyListeners();
      return records;
    } on Unreachable {
      _wasUnreachable = true;
      notifyListeners();
      return const [];
    }
  }

  /// Marks the refusals as seen. Does not undo anything — the write is already
  /// gone or already queued; this only clears the badge.
  Future<void> acknowledge() async {
    _needAttention = const [];
    notifyListeners();
  }

  Future<void> _saveOutbox() async {
    await _store.writeCollection(
      StoreKeys.outbox,
      _outbox.map((write) => write.toJson()).toList(growable: false),
    );
  }
}
