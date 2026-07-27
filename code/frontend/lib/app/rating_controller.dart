import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../features/lifecycle/job_lifecycle.dart';
import '../features/ratings/rating_rules.dart';
import '../models/job.dart';
import '../models/rating.dart';
import '../services/local_store.dart';

/// Holds the ratings and works out what a worker's profile shows.
class RatingController extends ChangeNotifier {
  RatingController(
    this._store, {
    this.rules = const RatingRules(),
    this.uuid = const Uuid(),
  });

  final LocalStore _store;
  final RatingRules rules;

  @visibleForTesting
  final Uuid uuid;

  List<Rating> _ratings = const <Rating>[];

  /// Every rating this device knows about.
  ///
  /// Deliberately not filtered here: the *rules* decide what is public, and a
  /// screen that wants a number asks [standingFor] rather than reading this.
  List<Rating> get all => _ratings;

  void load() {
    final raw = _store.readCollection(StoreKeys.ratings);
    _ratings = (raw ?? const []).map(Rating.fromJson).toList(growable: false);
    notifyListeners();
  }

  List<Rating> forJob(String jobId) =>
      _ratings.where((r) => r.jobId == jobId).toList(growable: false);

  bool canRate(Job job, {required JobRole role}) =>
      rules.canRate(job, role: role, existing: forJob(job.id));

  /// Records one person's score of the other.
  ///
  /// Returns null when the rating is not allowed — a second attempt, a job
  /// that was cancelled rather than finished, a score outside one to five.
  /// Null rather than an exception: by the time a stale button is tapped the
  /// screen behind it has usually moved on.
  Future<Rating?> rate(
    Job job, {
    required JobRole role,
    required int stars,
    String? note,
  }) async {
    if (!rules.isValidScore(stars)) return null;
    if (!canRate(job, role: role)) return null;

    final trimmed = note?.trim();
    final rating = Rating(
      id: uuid.v4(),
      jobId: job.id,
      side: rules.ratedBy(role),
      stars: stars,
      createdAt: DateTime.now(),
      note: (trimmed?.isEmpty ?? true) ? null : trimmed,
    );

    _ratings = [..._ratings, rating];
    notifyListeners();

    await _store.writeCollection(
      StoreKeys.ratings,
      _ratings.map((r) => r.toJson()).toList(),
    );

    return rating;
  }

  /// The three public numbers for the worker on this device.
  ///
  /// [jobs] is every job the app knows about; the completed ones this worker
  /// was chosen for are picked out here.
  WorkerStanding standingFor(String workerId, {required List<Job> jobs}) {
    final theirJobs = jobs
        .where((job) => job.isCompletedBy(workerId))
        .toList(growable: false);

    final theirJobIds = theirJobs.map((job) => job.id).toSet();

    return rules.standingFor(
      ratings: _ratings
          .where((r) => theirJobIds.contains(r.jobId))
          .toList(growable: false),
      completedJobs: theirJobs,
    );
  }
}
