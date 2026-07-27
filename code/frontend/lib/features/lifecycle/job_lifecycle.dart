import '../../models/job.dart';
import '../../models/job_status.dart';

/// Who is looking at a job.
///
/// Derived from the active demo account: the hirer is whoever posted it, the
/// worker is whoever was accepted onto it, and everybody else is a bystander.
/// P1-8 replaces the demo account with a real one and this stops being a
/// choice.
enum JobRole { hirer, worker, bystander }

/// Something a person can do to a job right now.
enum JobAction {
  /// The hirer says the worker has arrived and work has begun.
  confirmArrival,

  /// The hirer says the work is done.
  markComplete,

  /// Either side calls it off.
  cancel,
}

/// The rules about moving a job through its life (Section 7).
///
/// Pure functions over plain data, like [JobVisibility] and [BiddingRules].
/// This decides when money changes hands and when an address is revealed, and
/// it should be checkable without a widget or a database.
class JobLifecycle {
  const JobLifecycle();

  /// How long an unaccepted job stays on the map before it expires.
  ///
  /// Section 7 does not give a number. Seven days is chosen to be visibly
  /// generous: a job nobody has bid on is more likely to be badly described
  /// than genuinely finished, and expiring it early loses a hirer who would
  /// have got there.
  static const openJobLifetime = Duration(days: 7);

  /// Who [job] belongs to, from this device's point of view.
  JobRole roleFor(Job job, {required String viewerId}) {
    if (job.isPostedBy(viewerId)) return JobRole.hirer;
    if (job.acceptedWorkerId == viewerId) return JobRole.worker;
    return JobRole.bystander;
  }

  /// What this person can do to this job, in the order it should be offered.
  ///
  /// Deliberately not "what is technically possible". A bystander can do
  /// nothing at all, and the worker's only power is to withdraw — Section 7
  /// gives arrival and completion to the hirer, because the hirer is the one
  /// who can see whether anybody turned up.
  List<JobAction> actionsFor(Job job, {required JobRole role}) {
    if (role == JobRole.bystander) return const [];
    if (!job.status.isLive) return const [];

    return switch ((role, job.status)) {
      (JobRole.hirer, JobStatus.open) => const [JobAction.cancel],
      (JobRole.hirer, JobStatus.accepted) => const [
        JobAction.confirmArrival,
        JobAction.cancel,
      ],
      (JobRole.hirer, JobStatus.inProgress) => const [
        JobAction.markComplete,
        JobAction.cancel,
      ],
      // The worker can walk away, and that is all. Letting them mark a job
      // complete would let them claim a fare the hirer has not agreed was
      // earned.
      (JobRole.worker, _) => const [JobAction.cancel],
      _ => const [],
    };
  }

  /// The status [action] moves [job] to, or null when it is not allowed.
  ///
  /// Returning null rather than throwing: a stale button is a race, not a
  /// programming error, and the screen behind it has already moved on.
  JobStatus? resultOf(
    JobAction action, {
    required Job job,
    required JobRole role,
  }) {
    if (!actionsFor(job, role: role).contains(action)) return null;

    return switch (action) {
      JobAction.confirmArrival => JobStatus.inProgress,
      JobAction.markComplete => JobStatus.completed,
      JobAction.cancel => JobStatus.cancelled,
    };
  }

  /// Whether an open job has sat unclaimed long enough to expire.
  ///
  /// Only ever applies to [JobStatus.open]: once somebody is committed, the
  /// job is between two people and the clock stops mattering.
  bool hasExpired(Job job, {required DateTime now}) {
    if (job.status != JobStatus.open) return false;
    return now.difference(job.createdAt) > openJobLifetime;
  }

  /// Whether the two sides may see each other's exact location.
  ///
  /// **Section 5, and it replaces a promise the POC made.** Until a worker is
  /// chosen, both sides see a general area and a distance — the worker does
  /// not get the address, and the hirer does not get the worker's position
  /// either. Once the job is accepted the reveal is mutual and symmetric.
  ///
  /// A bystander never sees it, at any status. The people who can are the two
  /// who agreed to meet.
  bool revealsExactLocation(Job job, {required JobRole role}) {
    if (role == JobRole.bystander) return false;
    return job.status.hasWorker;
  }
}
