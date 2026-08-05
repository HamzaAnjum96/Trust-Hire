import '../models/message.dart';
import 'backend/remote_api.dart';
import 'local_store.dart';

/// Reads and writes messages.
///
/// The same shape as [BidRepository]: an interface the app talks to, backed by
/// local storage. Nothing above this line knows where messages live.
class MessageRepository {
  const MessageRepository(this._store, [this._queue]);

  final LocalStore _store;

  /// Where a write goes once it is on the device. See [QueueWrite].
  final QueueWrite? _queue;

  Future<List<Message>> fetchMessages() async {
    final stored = _store.readCollection(StoreKeys.messages) ?? const [];
    return stored.map(Message.fromJson).toList(growable: false);
  }

  Future<void> saveMessage(Message message) async {
    final all = [...await fetchMessages()];
    final index = all.indexWhere((m) => m.id == message.id);

    if (index == -1) {
      all.add(message);
    } else {
      all[index] = message;
    }

    await _write(all, changed: [message]);
  }

  /// Replaces the whole collection.
  ///
  /// Marking a thread read touches every unread message in it at once, and
  /// doing that one save at a time would rewrite the file per message.
  Future<void> saveAll(List<Message> messages, {Iterable<Message> changed = const []}) =>
      _write(messages, changed: changed);

  /// Deleting a job takes its conversation with it.
  ///
  /// The alternative is a thread with no job, which nothing can open and
  /// nothing will ever clean up.
  Future<void> deleteMessagesFor(String jobId) async {
    final remaining = (await fetchMessages())
        .where((message) => message.jobId != jobId)
        .toList();

    await _write(remaining);
  }

  Future<void> _write(
    List<Message> messages, {
    Iterable<Message> changed = const [],
  }) async {
    await _store.writeCollection(
      StoreKeys.messages,
      messages.map((message) => message.toJson()).toList(),
    );

    // Only what changed. Opening a thread with nine unread messages marks all
    // nine read, and offering the server nine writes for one act is the same
    // mistake the bid repository already avoids.
    final now = DateTime.now();
    for (final message in changed) {
      await _queue?.call(
        PendingWrite(
          entity: RemoteEntity.message,
          id: message.id,
          data: message.toJson(),
          madeAt: now,
        ),
      );
    }
  }
}
