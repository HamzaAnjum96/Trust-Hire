import '../l10n/app_localizations.dart';

/// Where a job is in its life.
///
/// Section 7 of the Phase 1 spec. The order matters: a job moves forward
/// through [open], [accepted], [inProgress], [completed], and can drop out to
/// [cancelled] or [expired] on the way. Nothing goes backwards — a completed
/// job cannot become open again, and a cancelled one is finished rather than
/// reopened, because the fare was locked against a worker who is no longer
/// doing it.
enum JobStatus {
  /// Posted, taking offers.
  open,

  /// A worker has been chosen and the fare is locked. Nobody has started.
  accepted,

  /// The worker has arrived and the hirer has said so.
  inProgress,

  /// Done.
  completed,

  /// Called off by either side before it finished.
  cancelled,

  /// Nobody was chosen in time.
  expired;

  String get id => name;

  static JobStatus fromId(String? id) =>
      JobStatus.values.firstWhere((s) => s.id == id, orElse: () => open);

  /// Whether the job is still going somewhere.
  bool get isLive =>
      this == JobStatus.open ||
      this == JobStatus.accepted ||
      this == JobStatus.inProgress;

  /// Whether a worker has been committed to it.
  ///
  /// The line the location reveal turns on: before this, both sides see a
  /// distance and an area; after it, they see each other's exact point.
  bool get hasWorker =>
      this == JobStatus.accepted ||
      this == JobStatus.inProgress ||
      this == JobStatus.completed;

  /// Whether the job is taking offers.
  bool get isTakingOffers => this == JobStatus.open;

  String label(AppStrings strings) => switch (this) {
    JobStatus.open => strings.statusOpen,
    JobStatus.accepted => strings.statusAccepted,
    JobStatus.inProgress => strings.statusInProgress,
    JobStatus.completed => strings.statusCompleted,
    JobStatus.cancelled => strings.statusCancelled,
    JobStatus.expired => strings.statusExpired,
  };
}
