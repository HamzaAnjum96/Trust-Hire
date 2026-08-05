import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trust_hire/app/message_controller.dart';
import 'package:trust_hire/features/messaging/messaging_rules.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_status.dart';
import 'package:trust_hire/models/message.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/media_store.dart';
import 'package:trust_hire/services/message_repository.dart';

/// The thread attached to a job.
///
/// **The load-bearing rule is who may read it.** A thread is between the two
/// people who agreed to meet, and everything in it is on the same device as
/// everybody else's — so the check deciding who belongs is the only thing
/// standing between a private conversation and a public one.
///
/// The second is *when* it opens. Not during bidding: a channel to every bidder
/// turns a job with nine offers into nine conversations the hirer never asked
/// for, and is the obvious way to take a deal off the platform before the
/// platform has done anything for it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  const rules = MessagingRules();
  final now = DateTime(2026, 8, 5, 12);
  DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));

  Job job({
    String id = 'j1',
    JobStatus status = JobStatus.accepted,
    String hirer = 'hina',
    String? worker = 'usman',
    String? booked,
  }) => Job(
    id: id,
    location: const JobLocation(latitude: 31.5, longitude: 74.3),
    createdAt: ago(6000),
    title: 'Fix a leaking tap',
    postedBy: hirer,
    acceptedWorkerId: worker,
    bookedWorkerId: booked,
    status: status,
  );

  Message message(
    String id, {
    String senderId = 'usman',
    String jobId = 'j1',
    String body = 'On my way',
    int minutesAgo = 10,
    bool read = false,
  }) => Message(
    id: id,
    jobId: jobId,
    senderId: senderId,
    body: body,
    sentAt: ago(minutesAgo),
    readAt: read ? ago(minutesAgo - 1) : null,
  );

  group('who the thread belongs to', () {
    test('the hirer and the worker, and nobody else', () {
      // **The privacy boundary.** Every message on the device sits in one
      // list; this is what keeps a conversation between two people.
      expect(rules.belongsTo(job(), 'hina'), isTrue);
      expect(rules.belongsTo(job(), 'usman'), isTrue);
      expect(rules.belongsTo(job(), 'bilal'), isFalse);
    });

    test('a bystander cannot write into it', () {
      expect(
        rules.refuse(job(), viewerId: 'bilal', body: 'hello'),
        MessageRefusal.notYours,
      );
    });

    test('and a booked worker is not a bystander', () {
      // A direct booking that has not been answered yet. The job is addressed
      // to that one person, so they are already in the conversation.
      final booking = job(status: JobStatus.accepted, worker: null, booked: 'usman');
      expect(rules.belongsTo(booking, 'usman'), isTrue);
    });
  });

  group('when the thread opens', () {
    test('not while the job is still taking offers', () {
      // A channel to every bidder is nine conversations the hirer never asked
      // for, and the easiest way to take a deal off the platform.
      expect(rules.isOpen(job(status: JobStatus.open, worker: null)), isFalse);
      expect(
        rules.refuse(
          job(status: JobStatus.open, worker: null),
          viewerId: 'hina',
          body: 'are you free?',
        ),
        MessageRefusal.notYetOpen,
      );
    });

    test('and once open it never closes again', () {
      // **The bug this caught.** Keying off `JobStatus.hasWorker` — which the
      // location reveal uses — made the thread vanish the moment a job was
      // cancelled, because a cancelled job is not `hasWorker`. That is exactly
      // the case where somebody wants to read back what was agreed.
      for (final status in JobStatus.values) {
        expect(
          rules.isOpen(job(status: status)),
          isTrue,
          reason: 'a job with a worker on it lost its thread at $status',
        );
        expect(
          rules.isOpen(job(status: status, worker: null)),
          isFalse,
          reason: 'a job with nobody on it grew a thread at $status',
        );
      }
    });

    test('and stays readable after the job is called off', () {
      // Read-only rather than gone: what was said still matters if anybody
      // disputes it later.
      final cancelled = job(status: JobStatus.cancelled);
      expect(rules.isOpen(cancelled), isTrue);
      expect(rules.acceptsMessages(cancelled), isFalse);
      expect(
        rules.refuse(cancelled, viewerId: 'hina', body: 'hello'),
        MessageRefusal.threadClosed,
      );
    });

    test('but a finished job can still be talked about', () {
      // Where to leave the key, when payment lands, a question about what was
      // done. Finishing the work is often when the talking starts.
      expect(rules.acceptsMessages(job(status: JobStatus.completed)), isTrue);
      expect(
        rules.refuse(
          job(status: JobStatus.completed),
          viewerId: 'hina',
          body: 'thank you',
        ),
        isNull,
      );
    });
  });

  group('what can be sent', () {
    test('nothing blank', () {
      expect(
        rules.refuse(job(), viewerId: 'hina', body: '   \n  '),
        MessageRefusal.empty,
      );
    });

    test('and nothing longer than a message', () {
      expect(
        rules.refuse(
          job(),
          viewerId: 'hina',
          body: 'x' * (MessagingRules.maxLength + 1),
        ),
        MessageRefusal.tooLong,
      );
      expect(
        rules.refuse(
          job(),
          viewerId: 'hina',
          body: 'x' * MessagingRules.maxLength,
        ),
        isNull,
      );
    });
  });

  group('unread counts', () {
    final thread = [
      message('m1', senderId: 'usman', minutesAgo: 30, read: true),
      message('m2', senderId: 'usman', minutesAgo: 20),
      message('m3', senderId: 'hina', minutesAgo: 10),
      message('m4', senderId: 'usman', minutesAgo: 5),
    ];

    test('your own messages never count, however old', () {
      final onlyMine = [
        message('a', senderId: 'usman', minutesAgo: 90),
        message('b', senderId: 'usman', minutesAgo: 60),
      ];

      expect(
        rules.unread(onlyMine, job: job(), viewerId: 'usman'),
        0,
        reason: 'Usman was counted as not having read his own messages',
      );

      // And the other side does see them.
      expect(rules.unread(onlyMine, job: job(), viewerId: 'hina'), 2);
    });

    test('and a read one stops counting', () {
      expect(rules.unread(thread, job: job(), viewerId: 'hina'), 2);
    });

    test('marking read touches only this thread and only the other side', () {
      final other = [...thread, message('m5', jobId: 'j2', senderId: 'usman')];

      final after = rules.markRead(
        other,
        jobId: 'j1',
        viewerId: 'hina',
        at: now,
      );

      expect(rules.unread(after, job: job(), viewerId: 'hina'), 0);
      expect(
        rules.unread(after, job: job(id: 'j2'), viewerId: 'hina'),
        1,
        reason: 'opening one thread marked another one read',
      );
      expect(
        after.firstWhere((m) => m.id == 'm3').isRead,
        isFalse,
        reason: "Hina's own message was marked as read by Hina",
      );
    });

    test('a conversation you are not part of is not your unread count', () {
      // **The bug this caught.** `unread` took only a job *id*, so it counted
      // every unread message on the device — and the device holds everybody's.
      // The Activity tab read "Messages · 20" beside three conversations.
      // `belongsTo` existed and was tested; nothing here consulted it.
      final theirs = [
        message('x1', senderId: 'bilal', jobId: 'other', minutesAgo: 5),
        message('x2', senderId: 'sana', jobId: 'other', minutesAgo: 4),
      ];
      final notMine = job(id: 'other', hirer: 'bilal', worker: 'sana');

      expect(
        rules.unread(theirs, job: notMine, viewerId: 'hina'),
        0,
        reason: "Hina was counted as owing a reply to somebody else's thread",
      );
      expect(
        rules.unreadByJob(theirs, jobs: [notMine], viewerId: 'hina'),
        isEmpty,
      );

      // And the two people actually in it still see it.
      expect(rules.unread(theirs, job: notMine, viewerId: 'bilal'), 1);
    });

    test('the by-job map agrees with the per-job count', () {
      // Two ways to ask the same question; the screen uses one and the badge
      // uses the other.
      final counts = rules.unreadByJob(
        thread,
        jobs: [job()],
        viewerId: 'hina',
      );
      expect(counts['j1'], rules.unread(thread, job: job(), viewerId: 'hina'));
    });
  });

  group('the order a conversation is read in', () {
    test('is oldest first — the opposite of the notification feed', () {
      final jumbled = [
        message('c', minutesAgo: 5),
        message('a', minutesAgo: 30),
        message('b', minutesAgo: 20),
      ];

      expect(
        rules.thread(jumbled, 'j1').map((m) => m.id),
        ['a', 'b', 'c'],
      );
    });

    test('and it holds only this job', () {
      final mixed = [
        message('a', jobId: 'j1'),
        message('b', jobId: 'j2'),
      ];

      expect(rules.thread(mixed, 'j1').map((m) => m.id), ['a']);
    });
  });

  group('sending, end to end', () {
    Future<MessageController> controller() async {
      final store = await LocalStore.open();
      return MessageController(MessageRepository(store))..setAccount('hina');
    }

    test('a message lands and survives a restart', () async {
      final store = await LocalStore.open();
      final messages = MessageController(MessageRepository(store))
        ..setAccount('hina');

      expect(await messages.send(job(), 'Are you free tomorrow?'), isNull);

      final reopened = MessageController(MessageRepository(store))
        ..setAccount('hina');
      await reopened.load();

      expect(reopened.threadFor('j1'), hasLength(1));
      expect(reopened.threadFor('j1').single.body, 'Are you free tomorrow?');
    });

    test('the body is trimmed on the way in', () async {
      final messages = await controller();
      await messages.send(job(), '  Coming now  ');

      expect(messages.threadFor('j1').single.body, 'Coming now');
    });

    test('a refused message is not stored', () async {
      final messages = await controller();

      expect(
        await messages.send(job(status: JobStatus.open, worker: null), 'hello'),
        MessageRefusal.notYetOpen,
      );
      expect(messages.threadFor('j1'), isEmpty);
    });

    test('opening a thread clears its count and nothing else', () async {
      final store = await LocalStore.open();
      final repository = MessageRepository(store);
      await repository.saveAll([
        message('m1', senderId: 'usman', jobId: 'j1'),
        message('m2', senderId: 'usman', jobId: 'j2'),
      ]);

      final messages = MessageController(repository)..setAccount('hina');
      await messages.load();
      expect(messages.threadsWaiting([job(), job(id: 'j2')]), 2);

      await messages.markRead(job());

      expect(messages.unreadFor(job()), 0);
      expect(messages.unreadFor(job(id: 'j2')), 1);
      expect(messages.threadsWaiting([job(), job(id: 'j2')]), 1);
    });

    test('the badge counts conversations, not messages', () async {
      // One person sending 23 lines is one thing to answer. A badge reading 23
      // says less than one reading 1, and sends the reader nowhere useful.
      final store = await LocalStore.open();
      final repository = MessageRepository(store);
      await repository.saveAll([
        for (var i = 0; i < 23; i++)
          message('m$i', senderId: 'usman', jobId: 'j1', minutesAgo: 100 - i),
      ]);

      final messages = MessageController(repository)..setAccount('hina');
      await messages.load();

      expect(messages.threadsWaiting([job()]), 1);
      expect(messages.unreadFor(job()), 23);
    });

    test('deleting a job takes its conversation with it', () async {
      final store = await LocalStore.open();
      final repository = MessageRepository(store);
      final messages = MessageController(repository)..setAccount('hina');

      await messages.send(job(), 'hello');
      await messages.deleteThread('j1');

      final reopened = MessageController(repository)..setAccount('hina');
      await reopened.load();

      expect(
        reopened.threadFor('j1'),
        isEmpty,
        reason: 'a thread with no job is one nothing can open and nothing '
            'will ever clean up',
      );
    });
  });

  group('the seeded conversations', () {
    test('only exist where the app itself would open a thread', () async {
      // Demo data the product cannot produce is a demo of something else, and
      // a thread on a job still taking offers is exactly that.
      final store = await LocalStore.open();
      final repository = JobRepository(store, MediaStore(store));
      await repository.ensureSeeded();

      final jobs = {for (final job in await repository.fetchJobs()) job.id: job};
      final messages = await MessageRepository(store).fetchMessages();

      expect(messages, isNotEmpty, reason: 'the demo has no conversations');

      for (final message in messages) {
        final job = jobs[message.jobId];
        expect(job, isNotNull, reason: '${message.id} is on no job at all');
        expect(
          rules.isOpen(job!),
          isTrue,
          reason: '${message.id} sits on a job whose thread never opened',
        );
      }
    });

    test('and somebody has something waiting, so a demo can show a badge', () async {
      final store = await LocalStore.open();
      await JobRepository(store, MediaStore(store)).ensureSeeded();

      final messages = await MessageRepository(store).fetchMessages();

      expect(
        messages.any((m) => !m.isRead),
        isTrue,
        reason: 'every seeded message is read, so the unread badge and the '
            '"new" highlight are unreachable in the demo',
      );
    });

    test('replies never arrive before the question', () async {
      // A conversation whose order is wrong is worse than no conversation.
      final store = await LocalStore.open();
      await JobRepository(store, MediaStore(store)).ensureSeeded();

      final messages = await MessageRepository(store).fetchMessages();
      final byJob = <String, List<Message>>{};
      for (final message in messages) {
        byJob.putIfAbsent(message.jobId, () => []).add(message);
      }

      for (final entry in byJob.entries) {
        final thread = rules.thread(entry.value, entry.key);
        for (var i = 1; i < thread.length; i++) {
          expect(
            thread[i].sentAt.isBefore(thread[i - 1].sentAt),
            isFalse,
            reason: 'thread ${entry.key} is out of order',
          );
        }
      }
    });
  });
}
