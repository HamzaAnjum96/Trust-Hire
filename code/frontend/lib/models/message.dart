/// One message in the thread attached to a job.
///
/// **A thread per job, not per pair of people.** Two people can hire each other
/// more than once, and a single rolling conversation would mix "are you coming
/// at nine?" about last month's tap with this week's wiring — with no way to
/// tell which job either sentence was about. Attaching it to the job means the
/// thread ends when the job does, and both sides can read back what was agreed
/// against the record of what was agreed.
class Message {
  const Message({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.readAt,
  });

  final String id;
  final String jobId;

  /// The account that wrote it. The *other* party is derived from the job
  /// rather than stored, because storing it would make a message that
  /// disagreed with the job possible.
  final String senderId;

  /// What was written. Never empty — an empty message is refused before it is
  /// built, so nothing downstream has to handle a blank bubble.
  final String body;

  final DateTime sentAt;

  /// When the person it was addressed to opened the thread, or null while it
  /// is still unread.
  ///
  /// **Per message, unlike the notification feed's single "seen up to here".**
  /// The feed is derived and could not carry per-entry state; messages are
  /// stored, so they can — and a conversation is the one place where "did they
  /// read it?" is worth the extra field. It is also what stops a thread's
  /// unread count from resetting every time the app restarts.
  final DateTime? readAt;

  bool get isRead => readAt != null;

  Message copyWith({DateTime? readAt}) => Message(
    id: id,
    jobId: jobId,
    senderId: senderId,
    body: body,
    sentAt: sentAt,
    readAt: readAt ?? this.readAt,
  );

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    jobId: json['jobId'] as String,
    senderId: json['senderId'] as String,
    body: json['body'] as String,
    sentAt: DateTime.parse(json['sentAt'] as String),
    readAt: json['readAt'] == null
        ? null
        : DateTime.parse(json['readAt'] as String),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'jobId': jobId,
    'senderId': senderId,
    'body': body,
    'sentAt': sentAt.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
  };
}
