import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trust_hire/app/sync_controller.dart';
import 'package:trust_hire/features/sync/sync_rules.dart';
import 'package:trust_hire/services/backend/mock_backend.dart';
import 'package:trust_hire/services/backend/remote_api.dart';
import 'package:trust_hire/services/local_store.dart';

/// P1-8b, against a backend that is not there.
///
/// **A mock that accepts everything proves nothing.** It is a dictionary with
/// latency, and a sync layer written against one looks correct right up until
/// it meets a server that says no. So the first group here is about the mock
/// refusing the same things `code/backend/migrations/` refuses, and the rest is
/// about what the outbox does when it is refused.
///
/// The single most important behaviour in this file is that a **permanent**
/// refusal leaves the queue. A write the server will refuse identically forever
/// sits at the head of an ordered outbox and stops everything behind it from
/// ever being sent — a queue that appears to be working and delivers nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  final madeAt = DateTime(2026, 7, 28, 10);

  PendingWrite write(
    RemoteEntity entity,
    String id,
    Map<String, dynamic> data, {
    int baseVersion = 0,
    int minute = 0,
    int attempts = 0,
  }) =>
      PendingWrite(
        entity: entity,
        id: id,
        data: data,
        madeAt: madeAt.add(Duration(minutes: minute)),
        baseVersion: baseVersion,
        attempts: attempts,
      );

  group('the mock refuses what the schema refuses', () {
    test('and every refusal it can give names where the rule comes from', () {
      // A mock that drifts from the thing it stands in for is worse than none:
      // it makes the app pass against a server that does not exist. So every
      // code the mock can return has to say which constraint it mirrors — and
      // the two that have no SQL equivalent have to say *that*, rather than
      // being quietly missing from the list.
      for (final code in RefusalCode.values) {
        final source = MockBackend.rulesEnforcedHere[code];
        expect(
          source,
          isNotNull,
          reason: '$code can be returned but names no rule behind it',
        );
        expect(
          source,
          anyOf(
            matches(RegExp(r'\(000\d_\w+\.sql\)$')),
            contains('no SQL equivalent'),
          ),
          reason: '$code should name its migration or say it has none',
        );
      }
    });

    test('the agreed fare is written once', () async {
      final backend = MockBackend();

      final first = await backend.push([
        write(RemoteEntity.job, 'job-1', {
          'postedBy': 'user-003',
          'acceptedWorkerId': 'user-009',
          'agreedFare': 1800,
          'status': 'accepted',
        }),
      ]);
      expect(first.isCompleteSuccess, isTrue);

      final second = await backend.push([
        write(
          RemoteEntity.job,
          'job-1',
          {
            'postedBy': 'user-003',
            'acceptedWorkerId': 'user-009',
            'agreedFare': 9000,
            'status': 'accepted',
          },
          baseVersion: 1,
        ),
      ]);

      expect(second.accepted, isEmpty);
      expect(second.refused.single.reason, RefusalReason.ruleRefusedIt);
      expect(second.refused.single.code, RefusalCode.fareIsLocked);
    });

    test('the chosen worker cannot be swapped', () async {
      final backend = MockBackend();
      await backend.push([
        write(RemoteEntity.job, 'job-1', {
          'postedBy': 'user-003',
          'acceptedWorkerId': 'user-009',
          'agreedFare': 1800,
        }),
      ]);

      final swap = await backend.push([
        write(
          RemoteEntity.job,
          'job-1',
          {
            'postedBy': 'user-003',
            'acceptedWorkerId': 'user-016',
            'agreedFare': 1800,
          },
          baseVersion: 1,
        ),
      ]);

      expect(swap.refused.single.code, RefusalCode.workerCannotBeSwapped);
    });

    test('nobody works for themselves', () async {
      final backend = MockBackend();

      final outcome = await backend.push([
        write(RemoteEntity.job, 'job-1', {
          'postedBy': 'user-003',
          'acceptedWorkerId': 'user-003',
        }),
      ]);

      expect(outcome.refused.single.code, RefusalCode.nobodyWorksForThemselves);
    });

    test('one accepted bid per job', () async {
      final backend = MockBackend();
      await backend.push([
        write(RemoteEntity.bid, 'bid-1', {
          'jobId': 'job-1',
          'workerId': 'user-009',
          'fare': 1800,
          'status': 'accepted',
        }),
      ]);

      final second = await backend.push([
        write(RemoteEntity.bid, 'bid-2', {
          'jobId': 'job-1',
          'workerId': 'user-016',
          'fare': 1600,
          'status': 'accepted',
        }),
      ]);

      expect(second.refused.single.code, RefusalCode.anotherOfferWasAccepted);
    });

    test('the accepted bid names the fare the job records', () async {
      final backend = MockBackend();
      await backend.push([
        write(RemoteEntity.job, 'job-1', {
          'postedBy': 'user-003',
          'acceptedWorkerId': 'user-009',
          'agreedFare': 1800,
        }),
      ]);

      final wrong = await backend.push([
        write(RemoteEntity.bid, 'bid-1', {
          'jobId': 'job-1',
          'workerId': 'user-009',
          'fare': 1200,
          'status': 'accepted',
        }),
      ]);

      expect(wrong.refused.single.code, RefusalCode.offerDoesNotMatchTheJob);
    });

    test('a ledger entry is never edited', () async {
      final backend = MockBackend();
      await backend.push([
        write(RemoteEntity.walletEntry, 'w-1', {
          'kind': 'commission',
          'tokens': -90,
          'jobId': 'job-1',
        }),
      ]);

      final edit = await backend.push([
        write(
          RemoteEntity.walletEntry,
          'w-1',
          {'kind': 'commission', 'tokens': 0, 'jobId': 'job-1'},
          baseVersion: 1,
        ),
      ]);

      expect(edit.refused.single.reason, RefusalReason.ruleRefusedIt);
      expect(edit.refused.single.code, RefusalCode.recordIsAppendOnly);
    });

    test('commission is charged once per job', () async {
      final backend = MockBackend();
      await backend.push([
        write(RemoteEntity.walletEntry, 'w-1', {
          'kind': 'commission',
          'tokens': -90,
          'jobId': 'job-1',
        }),
      ]);

      final again = await backend.push([
        write(RemoteEntity.walletEntry, 'w-2', {
          'kind': 'commission',
          'tokens': -90,
          'jobId': 'job-1',
        }),
      ]);

      expect(again.refused.single.code, RefusalCode.commissionAlreadyCharged);
    });

    test('an audit entry is never edited', () async {
      final backend = MockBackend();
      await backend.push([
        write(RemoteEntity.auditEntry, 'a-1', {
          'action': 'suspendUser',
          'note': 'Reported by two hirers.',
        }),
      ]);

      final edit = await backend.push([
        write(
          RemoteEntity.auditEntry,
          'a-1',
          {'action': 'suspendUser', 'note': 'something else'},
          baseVersion: 1,
        ),
      ]);

      expect(edit.refused.single.code, RefusalCode.recordIsAppendOnly);
    });

    test('only a finished job can be rated, once per side', () async {
      final backend = MockBackend();
      await backend.push([
        write(RemoteEntity.job, 'job-1', {
          'postedBy': 'user-003',
          'acceptedWorkerId': 'user-009',
          'status': 'inProgress',
        }),
      ]);

      final early = await backend.push([
        write(RemoteEntity.rating, 'r-1', {
          'jobId': 'job-1',
          'side': 'worker',
          'stars': 5,
        }),
      ]);
      expect(early.refused.single.code, RefusalCode.jobIsNotFinished);

      await backend.push([
        write(
          RemoteEntity.job,
          'job-1',
          {
            'postedBy': 'user-003',
            'acceptedWorkerId': 'user-009',
            'status': 'completed',
          },
          baseVersion: 1,
        ),
      ]);

      final ok = await backend.push([
        write(RemoteEntity.rating, 'r-1', {
          'jobId': 'job-1',
          'side': 'worker',
          'stars': 5,
        }),
      ]);
      expect(ok.isCompleteSuccess, isTrue);

      final twice = await backend.push([
        write(RemoteEntity.rating, 'r-2', {
          'jobId': 'job-1',
          'side': 'worker',
          'stars': 1,
        }),
      ]);
      expect(twice.refused.single.code, RefusalCode.alreadyRatedFromThatSide);
    });
  });

  group('the server assigns the time, not the phone', () {
    test('so two writes are ordered by the server clock', () async {
      // A device's clock is somebody's phone, and phones are wrong — often by
      // more than the gap between two edits. Ordering by one is how the later
      // of two changes loses.
      final backend = MockBackend();

      await backend.push([
        write(
          RemoteEntity.job,
          'job-1',
          {'postedBy': 'user-003'},
          minute: 100, // a phone claiming to be far in the future
        ),
      ]);
      await backend.push([
        write(RemoteEntity.job, 'job-2', {'postedBy': 'user-009'}, minute: 0),
      ]);

      final rows = await backend.pull();
      expect(
        rows.map((r) => r.id),
        ['job-1', 'job-2'],
        reason: 'the order is the order they arrived, not what they claimed',
      );
    });

    test('and a pull can ask only for what changed', () async {
      final backend = MockBackend();
      await backend.push([
        write(RemoteEntity.job, 'job-1', {'postedBy': 'user-003'}),
      ]);

      final first = await backend.pull();
      final mark = first.last.updatedAt;

      await backend.push([
        write(RemoteEntity.job, 'job-2', {'postedBy': 'user-009'}),
      ]);

      final second = await backend.pull(since: mark);
      expect(second.map((r) => r.id), ['job-2']);
    });
  });

  group('the outbox', () {
    Future<(SyncController, MockBackend, LocalStore)> ready() async {
      final store = await LocalStore.open();
      final backend = MockBackend();
      return (SyncController(store, backend)..load(), backend, store);
    }

    test('a queued write survives being closed while offline', () async {
      // The queue exists because the network is not there. An app closed while
      // offline would otherwise lose exactly the writes it was protecting.
      final store = await LocalStore.open();
      final backend = MockBackend();

      final sync = SyncController(store, backend)..load();
      await sync.enqueue(
        write(RemoteEntity.job, 'job-1', {'postedBy': 'user-003'}),
      );

      final reopened = SyncController(store, backend)..load();
      expect(reopened.outbox, hasLength(1));
      expect(reopened.outbox.single.id, 'job-1');
    });

    test('offline keeps everything and says so', () async {
      final (sync, backend, _) = await ready();
      backend.offline = true;

      await sync.enqueue(
        write(RemoteEntity.job, 'job-1', {'postedBy': 'user-003'}),
      );
      await sync.push();

      expect(sync.outbox, hasLength(1));
      expect(sync.outbox.single.attempts, 1);

      // `now` is passed because the fixture's writes are dated: left to the
      // real clock this queue is a day old, which is the *other* state — see
      // the stuck-a-long-time test below.
      expect(sync.state(now: madeAt), SyncState.offline);
      expect(sync.needAttention, isEmpty, reason: 'nothing has gone wrong yet');
    });

    test('and drains once the connection comes back', () async {
      final (sync, backend, _) = await ready();
      backend.offline = true;

      await sync.enqueue(
        write(RemoteEntity.job, 'job-1', {'postedBy': 'user-003'}),
      );
      await sync.push();

      backend.offline = false;
      await sync.push();

      expect(sync.outbox, isEmpty);
      expect(sync.state(now: madeAt), SyncState.settled);
      expect(backend.rowFor(RemoteEntity.job, 'job-1'), isNotNull);
    });

    test('a permanent refusal leaves the queue, and is reported', () async {
      // **The one that matters.** A write the server will refuse identically
      // forever sits at the head of an ordered queue and stops everything
      // behind it from being sent — a queue that looks busy and delivers
      // nothing.
      final (sync, backend, _) = await ready();

      await backend.push([
        write(RemoteEntity.job, 'job-1', {
          'postedBy': 'user-003',
          'acceptedWorkerId': 'user-009',
          'agreedFare': 1800,
        }),
      ]);

      await sync.enqueue(
        write(
          RemoteEntity.job,
          'job-1',
          {
            'postedBy': 'user-003',
            'acceptedWorkerId': 'user-009',
            'agreedFare': 9000,
          },
          baseVersion: 1,
        ),
      );
      await sync.enqueue(
        write(RemoteEntity.job, 'job-2', {'postedBy': 'user-003'}, minute: 1),
      );

      await sync.push();

      expect(sync.outbox, isEmpty, reason: 'the refused write must not linger');
      expect(sync.needAttention, hasLength(1));
      expect(
        sync.needAttention.single.reason,
        RefusalReason.ruleRefusedIt,
      );
      expect(sync.state(now: madeAt), SyncState.needsAttention);

      // And the write behind it landed rather than being stuck.
      expect(backend.rowFor(RemoteEntity.job, 'job-2'), isNotNull);
    });

    test('a stale write is reported rather than retried', () async {
      // Somebody else moved the row on. Sending the same edit again offers the
      // server something that was true yesterday.
      final (sync, backend, _) = await ready();

      await backend.push([
        write(RemoteEntity.job, 'job-1', {'postedBy': 'user-003'}),
      ]);
      await backend.push([
        write(
          RemoteEntity.job,
          'job-1',
          {'postedBy': 'user-003', 'title': 'Changed elsewhere'},
          baseVersion: 1,
        ),
      ]);

      await sync.enqueue(
        write(
          RemoteEntity.job,
          'job-1',
          {'postedBy': 'user-003', 'title': 'My offline edit'},
          baseVersion: 1,
        ),
      );
      await sync.push();

      expect(sync.outbox, isEmpty);
      expect(sync.needAttention.single.reason, RefusalReason.staleVersion);
      expect(sync.needAttention.single.code, RefusalCode.changedElsewhere);
    });

    test('writes are offered oldest first, whatever kind they are', () async {
      // Accepting an offer and locking a job's fare make sense in one order
      // only. A queue that sent all the jobs and then all the bids would offer
      // the server a job whose accepted bid never arrived.
      final (sync, _, _) = await ready();

      await sync.enqueue(
        write(RemoteEntity.bid, 'bid-1', {'jobId': 'job-1'}, minute: 5),
      );
      await sync.enqueue(
        write(RemoteEntity.job, 'job-1', {'postedBy': 'user-003'}, minute: 1),
      );

      const rules = SyncRules();
      expect(rules.order(sync.outbox).map((w) => w.id), ['job-1', 'bid-1']);
    });

    test('a queue that has been stuck a long time asks for a person', () async {
      final (sync, backend, _) = await ready();
      backend.offline = true;

      await sync.enqueue(
        write(RemoteEntity.job, 'job-1', {'postedBy': 'user-003'}),
      );
      await sync.push();

      // Ten minutes later it is no longer reassuring — the person may be about
      // to walk away believing a job was marked finished.
      expect(
        sync.state(now: madeAt.add(const Duration(minutes: 11))),
        SyncState.needsAttention,
      );
    });
  });

  group('what the rules decide', () {
    const rules = SyncRules();

    Refusal refusal(RefusalReason reason, {int attempts = 0}) => Refusal(
          write: write(
            RemoteEntity.job,
            'job-1',
            const {},
            attempts: attempts,
          ),
          reason: reason,
          code: RefusalCode.unreachable,
        );

    test('unreachable is retried', () {
      expect(
        rules.decide(refusal(RefusalReason.unreachable)),
        OutboxDecision.retry,
      );
    });

    test('a rule refusing it is final', () {
      expect(
        rules.decide(refusal(RefusalReason.ruleRefusedIt)),
        OutboxDecision.reportAndDrop,
      );
      expect(
        rules.decide(refusal(RefusalReason.staleVersion)),
        OutboxDecision.reportAndDrop,
      );
    });

    test('and retrying stops being persistence at some point', () {
      // Retrying forever is not persistence, it is a queue that never drains
      // and nobody looks at.
      expect(
        rules.decide(
          refusal(
            RefusalReason.unreachable,
            attempts: SyncRules.maxAttempts - 1,
          ),
        ),
        OutboxDecision.reportAndKeep,
      );
    });

    test('the server wins on anything it has already locked', () {
      final remote = RemoteRecord(
        entity: RemoteEntity.job,
        id: 'job-1',
        data: const {'agreedFare': 1800},
        updatedAt: madeAt,
        version: 3,
      );

      // An edit made offline against version 1 is working from something that
      // is no longer true, however recently it was made.
      expect(
        rules.localWins(remote, write(RemoteEntity.job, 'job-1', const {},
            baseVersion: 1, minute: 999)),
        isFalse,
      );
      expect(
        rules.localWins(remote, write(RemoteEntity.job, 'job-1', const {},
            baseVersion: 3)),
        isTrue,
      );
    });

    test('an append-only row never loses to a local copy', () {
      final entry = RemoteRecord(
        entity: RemoteEntity.walletEntry,
        id: 'w-1',
        data: const {'tokens': -90},
        updatedAt: madeAt,
        version: 1,
      );

      expect(
        rules.localWins(entry, write(RemoteEntity.walletEntry, 'w-1', const {},
            baseVersion: 1)),
        isFalse,
      );
    });
  });
}
