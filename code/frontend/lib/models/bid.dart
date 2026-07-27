/// One worker's offer on one job.
///
/// Section 4 models this on InDrive: the hirer posts a starting fare as an
/// opening point, workers counter, and the hirer picks — manually. There is no
/// auto-selection, not lowest-bid-wins and not first-come-first-served, and
/// nothing here should quietly become one.
class Bid {
  const Bid({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.fare,
    required this.createdAt,
    this.message,
    this.status = BidStatus.offered,
  });

  final String id;
  final String jobId;
  final String workerId;

  /// Rupees. Whole numbers: the audience does not think about a job in paisa,
  /// and a decimal point in a fare field is an invitation to mistype.
  final int fare;

  final DateTime createdAt;

  /// Optional. A worker who cannot write should be able to bid with a number
  /// alone, which is the same rule the posting form follows.
  final String? message;

  final BidStatus status;

  Bid copyWith({
    int? fare,
    String? message,
    bool clearMessage = false,
    BidStatus? status,
    DateTime? createdAt,
  }) {
    return Bid(
      id: id,
      jobId: jobId,
      workerId: workerId,
      fare: fare ?? this.fare,
      createdAt: createdAt ?? this.createdAt,
      message: clearMessage ? null : (message ?? this.message),
      status: status ?? this.status,
    );
  }

  factory Bid.fromJson(Map<String, dynamic> json) => Bid(
    id: json['id'] as String,
    jobId: json['jobId'] as String,
    workerId: json['workerId'] as String,
    fare: (json['fare'] as num).round(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    message: json['message'] as String?,
    status: BidStatus.fromId(json['status'] as String?),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'jobId': jobId,
    'workerId': workerId,
    'fare': fare,
    'createdAt': createdAt.toIso8601String(),
    'message': message,
    'status': status.id,
  };
}

/// Where a bid stands.
///
/// [passedOver] rather than "rejected": the hirer chose someone else, which is
/// not a judgement of this worker, and the word a worker reads should not
/// imply one.
enum BidStatus {
  offered,
  accepted,
  passedOver,
  withdrawn;

  String get id => name;

  static BidStatus fromId(String? id) =>
      BidStatus.values.firstWhere((s) => s.id == id, orElse: () => offered);

  bool get isOpen => this == BidStatus.offered;
}
