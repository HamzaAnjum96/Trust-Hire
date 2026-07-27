/// Which side of a job a rating is about.
enum RatedSide {
  /// The person who did the work. Shown publicly.
  worker,

  /// The person who posted it. Collected, never displayed — Section 10 keeps
  /// it for flagging problem hirers internally.
  hirer;

  String get id => name;

  static RatedSide fromId(String? id) =>
      RatedSide.values.firstWhere((s) => s.id == id, orElse: () => worker);

  /// Whether anyone other than an admin ever sees this.
  bool get isPublic => this == RatedSide.worker;
}

/// One person's score of the other, after a job.
class Rating {
  const Rating({
    required this.id,
    required this.jobId,
    required this.side,
    required this.stars,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String jobId;

  /// Who is being rated, not who is rating. The two are always opposite.
  final RatedSide side;

  /// One to five.
  final int stars;

  final DateTime createdAt;

  /// Optional, and never shown next to the public average — Section 10 gives
  /// no free-text review, and a five-star average with a paragraph beneath it
  /// is a review site. This exists for the admin panel in P1-7.
  final String? note;

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
    id: json['id'] as String,
    jobId: json['jobId'] as String,
    side: RatedSide.fromId(json['side'] as String?),
    stars: (json['stars'] as num).round(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    note: json['note'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'jobId': jobId,
    'side': side.id,
    'stars': stars,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };
}

/// What a worker's public profile shows.
///
/// Deliberately three numbers and nothing else. Section 10 gives an average
/// rating, a completed count and an **aggregated** fare average — never a
/// per-job breakdown, because the aggregate is what makes under-reporting a
/// fare self-defeating: a worker who declares less to dodge commission lowers
/// the figure future hirers anchor on.
class WorkerStanding {
  const WorkerStanding({
    required this.completedJobs,
    this.averageStars,
    this.averageFare,
  });

  final int completedJobs;

  /// Null until somebody has rated them. An unrated worker is new, not bad,
  /// and showing a zero would say the opposite.
  final double? averageStars;

  /// Across completed jobs. Null until there is one.
  final int? averageFare;

  bool get hasRating => averageStars != null;
  bool get hasHistory => completedJobs > 0;
}
