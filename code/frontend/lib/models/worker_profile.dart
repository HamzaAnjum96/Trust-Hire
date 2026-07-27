import 'job_tag.dart';

/// Which side of the marketplace someone is on.
///
/// One account, one role at a time. The spec describes a two-sided
/// marketplace, not a single feed with two modes — a worker's home is a feed
/// of leads, a hirer's is the jobs they posted.
enum UserRole {
  worker,
  hirer;

  String get id => name;

  /// Unset or unreadable reads as [worker].
  ///
  /// It is the useful default in both cases. A worker's home is a feed of
  /// real jobs; a hirer's is a list of the jobs they have posted, which on a
  /// first launch is empty. Defaulting to the empty one would make a working
  /// app look broken, and the feed exposes nothing private — it is the same
  /// public job data the map has always shown. Changing sides is one tap in
  /// settings.
  static UserRole fromId(String? id) =>
      UserRole.values.firstWhere((r) => r.id == id, orElse: () => worker);
}

/// A worker's tags, and the trust signals attached to them.
///
/// The tag list is the load-bearing part: it decides which jobs this worker
/// ever sees. It starts at [JobTag.defaultWorkerTags] — general work only —
/// and the worker adds their own trade if they choose to.
///
/// **Adding a trade never removes general work.** A part-time specialist still
/// needs to see general jobs, and quietly narrowing someone's feed because
/// they once tapped "Plumbing" would take work away from them without saying
/// so.
class WorkerProfile {
  WorkerProfile({
    required this.userId,
    Set<JobTag>? tags,
    this.completedJobs = 0,
    this.averageFare,
    this.rating,
  }) : tags = {...JobTag.defaultWorkerTags, ...?tags};

  final String userId;

  /// Always contains [JobTag.misc]; the constructor guarantees it.
  final Set<JobTag> tags;

  final int completedJobs;

  /// Aggregate across completed jobs, never a per-job breakdown. Section 10
  /// makes this the deterrent against under-reporting fares: a low number
  /// becomes the figure future hirers anchor on.
  final double? averageFare;

  /// Public. The hirer's own rating is collected but never shown (section 10).
  final double? rating;

  /// The trades this worker has opted into, beyond the default.
  Set<JobTag> get specialities =>
      tags.where((tag) => !JobTag.defaultWorkerTags.contains(tag)).toSet();

  bool get isSpecialised => specialities.isNotEmpty;

  WorkerProfile withTag(JobTag tag) => WorkerProfile(
    userId: userId,
    tags: {...tags, tag},
    completedJobs: completedJobs,
    averageFare: averageFare,
    rating: rating,
  );

  /// Removing a speciality is allowed; removing the default is not, since a
  /// worker with no tags would have an empty feed forever.
  WorkerProfile withoutTag(JobTag tag) {
    if (JobTag.defaultWorkerTags.contains(tag)) return this;

    return WorkerProfile(
      userId: userId,
      tags: {...tags}..remove(tag),
      completedJobs: completedJobs,
      averageFare: averageFare,
      rating: rating,
    );
  }

  factory WorkerProfile.fromJson(Map<String, dynamic> json) => WorkerProfile(
    userId: json['userId'] as String,
    tags: (json['tags'] as List<dynamic>?)
        ?.map((id) => JobTag.fromId(id as String))
        .whereType<JobTag>()
        .toSet(),
    completedJobs: json['completedJobs'] as int? ?? 0,
    averageFare: (json['averageFare'] as num?)?.toDouble(),
    rating: (json['rating'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'userId': userId,
    'tags': tags.map((t) => t.id).toList(),
    'completedJobs': completedJobs,
    'averageFare': averageFare,
    'rating': rating,
  };
}
