import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../features/messaging/messaging_rules.dart';
import '../models/job.dart';
import '../models/message.dart';
import '../services/message_repository.dart';

/// Holds every thread on the device, and which of them have something unread.
///
/// One controller for all threads rather than one per job: the Activity screen
/// and the navigation badge both need counts across every conversation at once,
/// and a per-thread controller would mean building one for each job to find out
/// there was nothing in it.
class MessageController extends ChangeNotifier {
  MessageController(
    this._repository, {
    this.rules = const MessagingRules(),
    this.uuid = const Uuid(),
  });

  final MessageRepository _repository;
  final MessagingRules rules;

  @visibleForTesting
  final Uuid uuid;

  List<Message> _messages = const <Message>[];
  String _viewerId = '';

  /// Every message this device knows about.
  ///
  /// Deliberately unfiltered: the *rules* decide who may read what, and a
  /// screen that wants a thread asks [threadFor] rather than reading this.
  List<Message> get all => _messages;

  Future<void> load() async {
    _messages = await _repository.fetchMessages();
    notifyListeners();
  }

  /// Whose side of every conversation this is.
  void setAccount(String id) {
    if (_viewerId == id) return;
    _viewerId = id;
    notifyListeners();
  }

  String get viewerId => _viewerId;

  List<Message> threadFor(String jobId) => rules.thread(_messages, jobId);

  int unreadFor(Job job) =>
      rules.unread(_messages, job: job, viewerId: _viewerId);

  /// Every job with something unread on it, and how much.
  ///
  /// Needs the jobs, because a count on a conversation you are not part of is
  /// not your count. See [MessagingRules.unread].
  Map<String, int> unreadByJob(Iterable<Job> jobs) =>
      rules.unreadByJob(_messages, jobs: jobs, viewerId: _viewerId);

  /// How many conversations are waiting — not how many messages.
  ///
  /// A badge reading 23 because one person sent 23 lines says less than one
  /// reading 2, and sends the reader to the wrong place.
  int threadsWaiting(Iterable<Job> jobs) => unreadByJob(jobs).length;

  /// Sends a message, or returns why it could not be sent.
  ///
  /// The refusal is returned rather than thrown: every caller has a sensible
  /// thing to show for each case, and an exception would make the ordinary
  /// path — an empty box — look like a failure.
  Future<MessageRefusal?> send(Job job, String body, {DateTime? at}) async {
    final refusal = rules.refuse(job, viewerId: _viewerId, body: body);
    if (refusal != null) return refusal;

    final message = Message(
      id: uuid.v4(),
      jobId: job.id,
      senderId: _viewerId,
      body: body.trim(),
      sentAt: at ?? DateTime.now(),
    );

    _messages = [..._messages, message];
    await _repository.saveMessage(message);
    notifyListeners();

    return null;
  }

  /// Marks everything addressed to the current account on [jobId] as read.
  ///
  /// Does nothing when there was nothing unread, so opening a thread twice
  /// does not rewrite storage.
  Future<void> markRead(Job job, {DateTime? at}) async {
    if (unreadFor(job) == 0) return;
    final jobId = job.id;

    final before = _messages;
    _messages = rules.markRead(
      _messages,
      jobId: jobId,
      viewerId: _viewerId,
      at: at ?? DateTime.now(),
    );

    // Only the ones that actually moved go to the queue.
    final changed = <Message>[
      for (var i = 0; i < _messages.length; i++)
        if (!identical(_messages[i], before[i])) _messages[i],
    ];

    await _repository.saveAll(_messages, changed: changed);
    notifyListeners();
  }

  /// Deleting a job takes its conversation with it.
  Future<void> deleteThread(String jobId) async {
    _messages = _messages
        .where((message) => message.jobId != jobId)
        .toList(growable: false);

    await _repository.deleteMessagesFor(jobId);
    notifyListeners();
  }
}
