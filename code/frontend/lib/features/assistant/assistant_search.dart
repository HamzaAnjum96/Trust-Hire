import '../../models/job.dart';
import '../../models/job_tag.dart';
import '../../models/premium.dart';
import '../../models/rating.dart';

/// Everything the assistant may look at, for one person, right now.
///
/// **Built from what the app already shows them, and nothing else.** The jobs
/// are the ones `ProfileController.visibleTo` lets through — Section 8's tag
/// and distance rule — so asking the assistant is never a way round it. The
/// workers are the directory listings that reach this person, as the
/// Directory tab shows them. Built by the screen, from the controllers; the
/// search below cannot see past it.
class AssistantData {
  const AssistantData({
    required this.jobs,
    required this.listings,
    required this.names,
    required this.standing,
    required this.now,
    required this.isWorker,
    this.myTrades = const {},
    this.here,
  });

  /// Open jobs this person can see.
  final List<Job> jobs;

  /// Directory listings within reach of this person.
  final List<DirectoryListing> listings;

  final Map<String, String> names;
  final Map<String, WorkerStanding> standing;
  final DateTime now;
  final bool isWorker;

  /// A worker's own trades — to say which one to add when a search for work
  /// comes back empty because of them.
  final Set<JobTag> myTrades;

  final JobLocation? here;
}

/// A job, as the assistant may describe it: what and roughly where, never
/// who or how to reach them.
class JobHit {
  const JobHit({
    required this.id,
    required this.title,
    required this.tags,
    required this.daysAgo,
    this.area,
    this.fare,
    this.km,
  });

  final String id;
  final String? title;
  final Set<JobTag> tags;
  final String? area;
  final int? fare;
  final double? km;
  final int daysAgo;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': ?title,
    'tags': [for (final tag in tags) tag.id],
    'area': ?area,
    'startingFare': ?fare,
    if (km != null) 'km': (km! * 10).round() / 10,
    'daysAgo': daysAgo,
  };
}

/// A directory worker, as the assistant may describe them: the public record
/// — name, trades, rating, prices — never a phone number. Booking goes
/// through the app.
class WorkerHit {
  const WorkerHit({
    required this.id,
    required this.name,
    required this.tags,
    this.headline,
    this.fromPrice,
    this.stars,
    this.jobsDone = 0,
    this.km,
  });

  final String id;
  final String name;
  final Set<JobTag> tags;
  final String? headline;
  final int? fromPrice;
  final double? stars;
  final int jobsDone;
  final double? km;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'trades': [for (final tag in tags) tag.id],
    'headline': ?headline,
    'fromPrice': ?fromPrice,
    if (stars != null) 'rating': (stars! * 10).round() / 10,
    'jobsDone': jobsDone,
    if (km != null) 'km': (km! * 10).round() / 10,
  };
}

/// The searches behind the assistant — read-only, over [AssistantData].
class AssistantSearch {
  const AssistantSearch({this.limit = 5, this.nearKm = 15});

  final int limit;

  /// What "near me" means: the middle of Section 6's 10–15 km.
  final double nearKm;

  List<JobHit> jobs(
    AssistantData data, {
    Set<JobTag> tags = const {},
    bool nearMe = false,
    List<String> words = const [],
  }) {
    final here = data.here;
    double? kmTo(Job job) =>
        here == null ? null : here.distanceTo(job.location) / 1000;

    var rows = [
      for (final job in data.jobs)
        if (tags.isEmpty || job.tags.any(tags.contains)) job,
    ];
    rows = _narrowed(rows, words, (job) => [
      job.title,
      job.area,
      job.shortDescription,
    ]);
    if (nearMe && here != null) {
      rows = [
        for (final job in rows)
          if ((kmTo(job) ?? 0) <= nearKm) job,
      ];
    }

    rows.sort((a, b) {
      final da = kmTo(a);
      final db = kmTo(b);
      if (da != null && db != null && da != db) return da.compareTo(db);
      return b.createdAt.compareTo(a.createdAt);
    });

    return [
      for (final job in rows.take(limit))
        JobHit(
          id: job.id,
          title: job.title,
          tags: job.tags,
          area: job.area,
          fare: job.startingFare,
          km: kmTo(job),
          daysAgo: data.now.difference(job.createdAt).inDays.clamp(0, 9999),
        ),
    ];
  }

  /// Workers for [tags], **best record first** — the one order the directory
  /// deliberately does not default to. It is right here because it is what
  /// was asked: "who's good for this?" is a question about the record, and
  /// answering it alphabetically would be refusing to answer.
  List<WorkerHit> workers(
    AssistantData data, {
    Set<JobTag> tags = const {},
    bool nearMe = false,
    List<String> words = const [],
  }) {
    final here = data.here;
    double? kmTo(DirectoryListing listing) {
      final base = listing.base;
      return here == null || base == null
          ? null
          : here.distanceTo(base) / 1000;
    }

    var rows = [
      for (final listing in data.listings)
        if (tags.isEmpty || listing.tags.any(tags.contains)) listing,
    ];
    rows = _narrowed(rows, words, (listing) => [
      data.names[listing.workerId],
      listing.headline,
      for (final service in listing.services) service.title,
    ]);
    if (nearMe && here != null) {
      rows = [
        for (final listing in rows)
          if ((kmTo(listing) ?? 0) <= nearKm) listing,
      ];
    }

    double score(DirectoryListing listing) {
      final standing = data.standing[listing.workerId];
      return (standing?.averageStars ?? 0) * 100 +
          (standing?.completedJobs ?? 0);
    }

    rows.sort((a, b) => score(b).compareTo(score(a)));

    return [
      for (final listing in rows.take(limit))
        WorkerHit(
          id: listing.workerId,
          name: data.names[listing.workerId] ?? '',
          tags: listing.tags,
          headline: listing.headline,
          fromPrice: listing.fromPrice,
          stars: data.standing[listing.workerId]?.averageStars,
          jobsDone: data.standing[listing.workerId]?.completedJobs ?? 0,
          km: kmTo(listing),
        ),
    ];
  }

  /// [rows] narrowed by [words] — unless that leaves nothing, in which case
  /// the words were probably not a filter ("painting jobs please") and are
  /// ignored rather than turning a good answer into no answer.
  static List<T> _narrowed<T>(
    List<T> rows,
    List<String> words,
    List<String?> Function(T row) fields,
  ) {
    if (words.isEmpty) return rows;
    final narrowed = [
      for (final row in rows)
        if (words.any(
          (word) => fields(row).any(
            (field) => field != null && field.toLowerCase().contains(word),
          ),
        ))
          row,
    ];
    return narrowed.isEmpty ? rows : narrowed;
  }
}
