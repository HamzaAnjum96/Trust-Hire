import '../../models/job.dart';
import '../../models/job_tag.dart';
import '../../models/worker_profile.dart';

/// Decides which jobs reach a worker's feed.
///
/// Section 8 of the Phase 1 spec calls this the mechanism that solves the
/// "everyone bids on everything, including jobs they can't do, then cancels"
/// problem. Two conditions, both required:
///
/// 1. **Tag overlap** — at least one of the job's tags is on the worker's
///    profile. A job tagged only "Legal advice" never reaches a worker sitting
///    on the default general tag, so it is never *shown and shouldn't be bid
///    on*; it is simply not shown.
/// 2. **Geofence** — the job is within its radius of the worker, unless the
///    hirer opened it to everywhere.
///
/// Kept as pure functions over plain data: this is the rule the whole
/// marketplace rests on, and it should be checkable without a widget, a
/// database or a network.
class JobVisibility {
  const JobVisibility({this.defaultRadiusMetres = 12000});

  /// Section 6 gives 10–15 km; the middle of that is the default when a job
  /// does not carry its own.
  final double defaultRadiusMetres;

  /// Whether [job] should appear in [worker]'s feed.
  ///
  /// [from] is the worker's position. When it is unknown the geofence stands
  /// down rather than emptying the feed — the same call the POC made for the
  /// distance filter, and for the same reason: a worker who declined location
  /// should lose sorting, not lose work.
  bool isVisibleTo(
    Job job, {
    required WorkerProfile worker,
    JobLocation? from,
  }) {
    if (!overlaps(job.tags, worker.tags)) return false;
    return isWithinGeofence(job, from: from);
  }

  /// True when the two tag sets share anything at all.
  static bool overlaps(Set<JobTag> jobTags, Set<JobTag> workerTags) =>
      jobTags.any(workerTags.contains);

  bool isWithinGeofence(Job job, {JobLocation? from}) {
    if (job.openToAllLocations) return true;
    if (from == null) return true;

    final radius = job.geofenceMetres ?? defaultRadiusMetres;
    return from.distanceTo(job.location) <= radius;
  }

  /// The feed: every visible job, newest first.
  List<Job> feedFor(
    List<Job> jobs, {
    required WorkerProfile worker,
    JobLocation? from,
  }) {
    return jobs
        .where((job) => isVisibleTo(job, worker: worker, from: from))
        .toList(growable: false);
  }

  /// Why a job did not reach a worker.
  ///
  /// Exists for the admin panel and for diagnosing "why can't I see this
  /// job?" — a question that is otherwise unanswerable from the outside, and
  /// which a worker losing income will reasonably ask.
  VisibilityFailure? explain(
    Job job, {
    required WorkerProfile worker,
    JobLocation? from,
  }) {
    if (!overlaps(job.tags, worker.tags)) return VisibilityFailure.noTagOverlap;
    if (!isWithinGeofence(job, from: from)) return VisibilityFailure.tooFar;
    return null;
  }
}

enum VisibilityFailure { noTagOverlap, tooFar }
