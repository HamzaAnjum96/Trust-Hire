import '../../models/job.dart';
import '../../models/job_status.dart';
import '../../models/message.dart';
import '../lifecycle/job_lifecycle.dart';

/// Why a message cannot be sent.
///
/// A code rather than a sentence, for the same reason every other refusal in
/// this codebase is: the screen localises it, and English prose in `lib/`
/// fails the localisation guard.
enum MessageRefusal {
  /// The thread has not opened yet — nobody has been chosen for this job.
  notYetOpen,

  /// The job is over in a way that leaves nothing to arrange.
  threadClosed,

  /// A bystander. The thread is between the two people who agreed to meet.
  notYours,

  /// Nothing but whitespace.
  empty,

  /// Longer than [MessagingRules.maxLength].
  tooLong,
}

/// Who may say what to whom, and when.
///
/// Pure functions over plain data, like every rules class before it.
class MessagingRules {
  const MessagingRules();

  /// Whether this job has a thread at all.
  ///
  /// **It opens the moment a worker is attached** — the same moment
  /// [JobLifecycle.revealsExactLocation] hands the two sides each other's
  /// position, on the same argument: the two people who agreed to meet are the
  /// two who get each other's details.
  ///
  /// It deliberately does **not** open during bidding. A worker who wants to
  /// ask a question before offering can put it in the offer's message, which
  /// the hirer reads next to the number it is about; opening a channel to
  /// every bidder would turn a job with nine offers into nine conversations
  /// the hirer never asked for, and would be the obvious way to take a deal
  /// off the platform before the platform has done anything.
  ///
  /// **And once open it never closes.** This asks about the worker rather than
  /// the status, because `JobStatus.hasWorker` is false for a cancelled job —
  /// so keying off it made a thread *disappear* the moment a job was called
  /// off, which is precisely the case where somebody wants to look back at
  /// what was agreed. [acceptsMessages] is what stops it taking new lines.
  bool isOpen(Job job) =>
      job.acceptedWorkerId != null || job.bookedWorkerId != null;

  /// Whether the thread still takes new messages.
  ///
  /// A cancelled or expired job has nothing left to arrange, so its thread
  /// goes read-only rather than disappearing — what was said still matters if
  /// anybody disputes it later.
  ///
  /// A *completed* job stays writable. The work being finished is often when
  /// the talking starts: where to leave the key, when payment lands, a
  /// question about what was done.
  bool acceptsMessages(Job job) => switch (job.status) {
    JobStatus.accepted || JobStatus.inProgress || JobStatus.completed => true,
    JobStatus.open || JobStatus.cancelled || JobStatus.expired => false,
  };

  /// Longer than anybody types on a phone in a hurry, short enough that a
  /// bubble is still a bubble.
  static const maxLength = 1000;

  /// Whether [viewerId] is one of the two people in this thread.
  bool belongsTo(Job job, String viewerId) =>
      const JobLifecycle().roleFor(job, viewerId: viewerId) !=
      JobRole.bystander;

  /// The other person's id, from [viewerId]'s point of view.
  ///
  /// Derived rather than stored: a message that disagreed with its job about
  /// who the parties were would be unfixable.
  String? otherParty(Job job, String viewerId) {
    if (job.isPostedBy(viewerId)) {
      return job.acceptedWorkerId ?? job.bookedWorkerId;
    }
    return job.postedBy;
  }

  /// Why [viewerId] cannot send [body] on [job], or null if they can.
  MessageRefusal? refuse(Job job, {required String viewerId, required String body}) {
    if (!belongsTo(job, viewerId)) return MessageRefusal.notYours;
    if (!isOpen(job)) return MessageRefusal.notYetOpen;
    if (!acceptsMessages(job)) return MessageRefusal.threadClosed;

    final trimmed = body.trim();
    if (trimmed.isEmpty) return MessageRefusal.empty;
    if (trimmed.length > maxLength) return MessageRefusal.tooLong;

    return null;
  }

  /// The thread for [jobId], oldest first — the order a conversation is read
  /// in, which is the opposite of the notification feed's.
  List<Message> thread(Iterable<Message> messages, String jobId) {
    final mine = messages.where((m) => m.jobId == jobId).toList()
      ..sort((a, b) {
        final byTime = a.sentAt.compareTo(b.sentAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });

    return List.unmodifiable(mine);
  }

  /// How many messages in [job]'s thread [viewerId] has not read.
  ///
  /// Your own messages never count, however long ago you sent them — and
  /// neither does anything on a job you have no part in.
  ///
  /// **[job] is required for that second reason.** The first version took only
  /// a job *id*, so it counted every unread message on the device and the
  /// Activity tab read "Messages · 20" beside three conversations. [belongsTo]
  /// existed and was tested; nothing here consulted it.
  int unread(
    Iterable<Message> messages, {
    required Job job,
    required String viewerId,
  }) {
    if (!belongsTo(job, viewerId)) return 0;

    return messages
        .where((m) => m.jobId == job.id && m.senderId != viewerId && !m.isRead)
        .length;
  }

  /// Every job [viewerId] has an unread message on, with the count.
  ///
  /// One pass over the whole collection rather than a call per job: the
  /// Activity screen needs this for every thread at once, and asking per job
  /// would be quadratic in the number of messages.
  ///
  /// Takes the jobs because the count is only meaningful for the ones this
  /// person is part of — see [unread].
  Map<String, int> unreadByJob(
    Iterable<Message> messages, {
    required Iterable<Job> jobs,
    required String viewerId,
  }) {
    final mine = <String, Job>{
      for (final job in jobs)
        if (belongsTo(job, viewerId)) job.id: job,
    };

    final counts = <String, int>{};
    for (final message in messages) {
      if (message.senderId == viewerId || message.isRead) continue;
      if (!mine.containsKey(message.jobId)) continue;
      counts[message.jobId] = (counts[message.jobId] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  /// [messages] with everything addressed to [viewerId] on [jobId] marked read.
  ///
  /// Returns the whole collection rather than only what changed, so the caller
  /// cannot save a partial list over a complete one.
  List<Message> markRead(
    Iterable<Message> messages, {
    required String jobId,
    required String viewerId,
    required DateTime at,
  }) => List.unmodifiable([
    for (final message in messages)
      if (message.jobId == jobId &&
          message.senderId != viewerId &&
          !message.isRead)
        message.copyWith(readAt: at)
      else
        message,
  ]);
}
