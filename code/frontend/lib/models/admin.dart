import 'verification.dart';

/// What an admin did.
///
/// A closed list, because Section 12's requirement is that "every admin action
/// (type, target user, notes, timestamp) is logged" — and a free-text type is
/// not something anybody can audit, sort or count.
enum AdminAction {
  approveUser,
  suspendUser,
  reinstateUser,

  /// The one moment a CNIC photo is looked at. Logged like everything else,
  /// which is what makes "only on a dispute" a claim somebody can check
  /// afterwards rather than a promise.
  viewCnic,

  adjustWallet,
  unlockWallet,
  cancelJob,
  closeDispute;

  String get id => name;

  static AdminAction fromId(String? id) => AdminAction.values.firstWhere(
    (action) => action.id == id,
    orElse: () => approveUser,
  );

  /// Whether this action changed somebody's money or their access.
  ///
  /// Used to mark the heavier entries in the log. Not a permission — an admin
  /// who can do one of these can do all of them — but a reader scanning a
  /// hundred lines should be able to find the ones that moved a balance.
  bool get isOverride =>
      this == AdminAction.adjustWallet ||
      this == AdminAction.unlockWallet ||
      this == AdminAction.suspendUser;
}

/// One line in the audit log.
///
/// Immutable and never deleted, like a wallet entry and for the same reason:
/// a record of what happened that can be edited afterwards is a record nobody
/// can rely on.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.adminId,
    required this.at,
    this.targetUserId,
    this.targetJobId,
    this.note,
    this.tokens,
  });

  final String id;
  final AdminAction action;

  /// Which admin. There is one in the POC, but the field exists because a log
  /// that cannot say *who* is half a log.
  final String adminId;

  final DateTime at;
  final String? targetUserId;
  final String? targetJobId;

  /// Why. Section 12 lists notes as part of every entry, and for an override
  /// the reason is the only thing that makes it reviewable.
  final String? note;

  /// The size of a wallet adjustment, signed. Null for everything else.
  final int? tokens;

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
    id: json['id'] as String,
    action: AdminAction.fromId(json['action'] as String?),
    adminId: json['adminId'] as String? ?? 'admin',
    at: DateTime.parse(json['at'] as String),
    targetUserId: json['targetUserId'] as String?,
    targetJobId: json['targetJobId'] as String?,
    note: json['note'] as String?,
    tokens: (json['tokens'] as num?)?.round(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'action': action.id,
    'adminId': adminId,
    'at': at.toIso8601String(),
    'targetUserId': targetUserId,
    'targetJobId': targetJobId,
    'note': note,
    'tokens': tokens,
  };
}

/// Where an account stands with the platform.
enum ReviewStatus {
  /// Signed up, not looked at yet.
  pending,

  approved,

  /// Stopped, by an admin, with a reason. Not deleted — Section 12 is about
  /// oversight, and an account that vanishes takes its history with it.
  suspended;

  String get id => name;

  static ReviewStatus fromId(String? id) => ReviewStatus.values.firstWhere(
    (status) => status.id == id,
    orElse: () => pending,
  );
}

/// What an admin sees about an account before deciding on it.
///
/// Two things, kept apart because they belong to different people: the
/// platform's decision ([status], [note], [decidedAt]) and what the account
/// holder submitted ([verification]). The signals read through to the same
/// [Verification] the worker's own screen writes — **one record, not a copy** —
/// so a re-submission cannot leave the panel deciding on the old one.
///
/// Those signals are Section 2's, and they are **signals**: a CNIC whose number
/// is the right shape, a phone that answered a code, and a name-match check
/// that can disagree. None of them is an identity check, and the panel says so
/// where it shows them — a false positive on the SIM match is a family
/// member's phone, not a fraudster.
class AccountReview {
  const AccountReview({
    required this.userId,
    this.status = ReviewStatus.pending,
    this.verification = const Verification(),
    this.note,
    this.decidedAt,
  });

  final String userId;
  final ReviewStatus status;

  /// What was submitted, and what the automated checks made of it.
  final Verification verification;

  final String? note;
  final DateTime? decidedAt;

  /// A photo was uploaded. **Not** that anybody has looked at it — Section 2
  /// is explicit that it "sits unreviewed unless a dispute is raised".
  bool get cnicOnFile => verification.cnicOnFile;

  /// The number is the right shape. An automated check, not a lookup: Section
  /// 13 rules out any live government database.
  bool get cnicPlausible => verification.cnicPlausible;

  bool get phoneVerified => verification.phoneVerified;

  /// False when the SIM's registered name does not match the CNIC.
  bool get simNameMatches => verification.simNameMatches;

  bool get isFlagged => verification.isFlagged;
  bool get needsDecision => status == ReviewStatus.pending;

  AccountReview copyWith({
    ReviewStatus? status,
    Verification? verification,
    String? note,
    DateTime? decidedAt,
  }) => AccountReview(
    userId: userId,
    status: status ?? this.status,
    verification: verification ?? this.verification,
    note: note ?? this.note,
    decidedAt: decidedAt ?? this.decidedAt,
  );

  factory AccountReview.fromJson(Map<String, dynamic> json) => AccountReview(
    userId: json['userId'] as String,
    status: ReviewStatus.fromId(json['status'] as String?),
    verification: Verification.fromJson(json),
    note: json['note'] as String?,
    decidedAt: json['decidedAt'] == null
        ? null
        : DateTime.parse(json['decidedAt'] as String),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'userId': userId,
    'status': status.id,
    ...verification.toJson(),
    'note': note,
    'decidedAt': decidedAt?.toIso8601String(),
  };
}

/// A complaint about a job, and the only thing that unlocks a CNIC.
///
/// Section 2: the photo "sits unreviewed unless a dispute is raised later, at
/// which point an admin manually pulls it up". So a dispute is not paperwork —
/// it is the key, and [AdminRules.mayOpenCnic] is the lock.
class Dispute {
  const Dispute({
    required this.id,
    required this.jobId,
    required this.aboutUserId,
    required this.raisedByUserId,
    required this.raisedAt,
    required this.reason,
    this.resolvedAt,
    this.resolution,
  });

  final String id;
  final String jobId;

  /// Who is being complained about. This is the account whose CNIC becomes
  /// openable, and nobody else's.
  final String aboutUserId;

  final String raisedByUserId;
  final DateTime raisedAt;
  final String reason;

  final DateTime? resolvedAt;
  final String? resolution;

  bool get isOpen => resolvedAt == null;

  Dispute closed({required DateTime at, required String resolution}) =>
      Dispute(
        id: id,
        jobId: jobId,
        aboutUserId: aboutUserId,
        raisedByUserId: raisedByUserId,
        raisedAt: raisedAt,
        reason: reason,
        resolvedAt: at,
        resolution: resolution,
      );

  factory Dispute.fromJson(Map<String, dynamic> json) => Dispute(
    id: json['id'] as String,
    jobId: json['jobId'] as String,
    aboutUserId: json['aboutUserId'] as String,
    raisedByUserId: json['raisedByUserId'] as String,
    raisedAt: DateTime.parse(json['raisedAt'] as String),
    reason: json['reason'] as String,
    resolvedAt: json['resolvedAt'] == null
        ? null
        : DateTime.parse(json['resolvedAt'] as String),
    resolution: json['resolution'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'jobId': jobId,
    'aboutUserId': aboutUserId,
    'raisedByUserId': raisedByUserId,
    'raisedAt': raisedAt.toIso8601String(),
    'reason': reason,
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolution': resolution,
  };
}

/// The CNIC a worker submitted, and the only thing in the app nobody may look
/// at casually.
///
/// The number is stored masked — the last four digits and the check digit are
/// enough for an admin to match a document against a claim, and there is no
/// point in the app holding a full national identity number it has no use
/// for. Section 13 rules out any lookup against it in any case.
class CnicRecord {
  const CnicRecord({
    required this.userId,
    required this.maskedNumber,
    required this.nameOnCard,
    required this.submittedAt,
    this.photoReference,
  });

  final String userId;

  /// `*****-*****45-6`. Never the whole number.
  final String maskedNumber;

  final String nameOnCard;
  final DateTime submittedAt;

  /// Where the photo lives. Null in the POC — no real documents are shipped
  /// with a demo, and a placeholder image of a national identity card is not
  /// a thing worth generating.
  final String? photoReference;

  factory CnicRecord.fromJson(Map<String, dynamic> json) => CnicRecord(
    userId: json['userId'] as String,
    maskedNumber: json['maskedNumber'] as String,
    nameOnCard: json['nameOnCard'] as String,
    submittedAt: DateTime.parse(json['submittedAt'] as String),
    photoReference: json['photoReference'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'userId': userId,
    'maskedNumber': maskedNumber,
    'nameOnCard': nameOnCard,
    'submittedAt': submittedAt.toIso8601String(),
    'photoReference': photoReference,
  };
}
