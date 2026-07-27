import '../../models/job.dart';
import '../../models/job_status.dart';
import '../../models/rating.dart';
import '../lifecycle/job_lifecycle.dart';

/// Section 10, as rules.
///
/// Pure functions over plain data, like the visibility, bidding and lifecycle
/// rules before it. What a worker's public number is decides what future
/// hirers offer them, so it should be checkable without a widget.
class RatingRules {
  const RatingRules();

  static const minStars = 1;
  static const maxStars = 5;

  /// Whether this person can rate this job now.
  ///
  /// Only after it finished, only the two people involved, and only once.
  /// A cancelled job is deliberately not ratable: nobody did any work, and a
  /// one-star rating for a job that never happened is a weapon rather than a
  /// signal.
  bool canRate(
    Job job, {
    required JobRole role,
    required List<Rating> existing,
  }) {
    if (job.status != JobStatus.completed) return false;
    if (role == JobRole.bystander) return false;

    return !existing.any((r) => r.jobId == job.id && r.side == ratedBy(role));
  }

  /// Who a given person rates. The two sides are always opposite — you cannot
  /// rate yourself.
  RatedSide ratedBy(JobRole role) =>
      role == JobRole.hirer ? RatedSide.worker : RatedSide.hirer;

  /// Whether a score is one a person could have meant.
  bool isValidScore(int stars) => stars >= minStars && stars <= maxStars;

  /// The public numbers for a worker.
  ///
  /// [ratings] should be every rating of them; [completedJobs] every job they
  /// finished. The fare average is computed from the jobs rather than from
  /// the ratings, because a worker who was never rated has still been paid.
  WorkerStanding standingFor({
    required List<Rating> ratings,
    required List<Job> completedJobs,
  }) {
    final ofWorker = ratings
        .where((r) => r.side == RatedSide.worker)
        .toList(growable: false);

    final fares = completedJobs
        .map((job) => job.agreedFare)
        .whereType<int>()
        .toList(growable: false);

    return WorkerStanding(
      completedJobs: completedJobs.length,
      averageStars: ofWorker.isEmpty
          ? null
          : ofWorker.fold<int>(0, (sum, r) => sum + r.stars) / ofWorker.length,
      // Rounded to whole rupees, like every other fare in the app.
      averageFare: fares.isEmpty
          ? null
          : fares.fold<int>(0, (sum, fare) => sum + fare) ~/ fares.length,
    );
  }

  /// Ratings of the *hirer*, which no screen may show.
  ///
  /// Exposed as its own method so the one place that needs them — the admin
  /// panel in P1-7 — has to ask for them by name. Section 10 collects these
  /// for flagging problem hirers and never displays them, and a general
  /// "ratings for this user" accessor would make leaking them a one-word
  /// mistake.
  List<Rating> internalHirerRatings(List<Rating> all) =>
      all.where((r) => r.side == RatedSide.hirer).toList(growable: false);
}
