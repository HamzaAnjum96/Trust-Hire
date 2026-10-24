import '../../models/job.dart';
import '../../models/job_status.dart';
import '../../models/job_tag.dart';
import 'fare_guard.dart';

/// One fare a hirer could compare theirs with.
class FareComparable {
  const FareComparable({
    required this.fare,
    required this.agreed,
    required this.tags,
    required this.daysAgo,
    this.km,
    this.title,
    this.area,
  });

  final int fare;

  /// True for what the work actually went for — the fare locked when the
  /// hirer chose an offer. False for what a hirer opened at, which is only
  /// what somebody hoped to pay.
  final bool agreed;

  final Set<JobTag> tags;
  final double? km;
  final String? title;
  final String? area;
  final int daysAgo;

  /// What the fare agent is sent. Never who posted it, who did it, or how to
  /// reach them: a fare is market information, the people behind it are not.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'fare': fare,
    'agreed': agreed,
    'tags': [for (final tag in tags) tag.id],
    'km': km == null ? null : (km! * 10).round() / 10,
    'title': title,
    'area': area,
    'daysAgo': daysAgo,
  };
}

/// Where a fare suggestion comes from: what similar work on the device went
/// for.
///
/// **A pure function over the jobs already stored**, like the notification
/// feed — nothing records fares separately, so there is nothing to keep in
/// step. The same list is what the fare agent is given, which is the point:
/// the agent and the on-device estimate can disagree about what the evidence
/// means, never about what it is.
class FareEvidence {
  const FareEvidence._();

  /// The fare agent is sent at most this many, nearest and agreed first.
  static const limit = 300;

  /// Every job sharing a tag with [tags] that carries a fare, best first.
  ///
  /// Agreed fares from called-off jobs are left out: an agreement that fell
  /// through says less about the price than the hirer's opening number did.
  static List<FareComparable> gather(
    Iterable<Job> jobs, {
    required Set<JobTag> tags,
    required DateTime now,
    JobLocation? near,
    String? excludingJobId,
  }) {
    if (tags.isEmpty) return const [];

    final found = <FareComparable>[];
    for (final job in jobs) {
      if (job.id == excludingJobId) continue;
      if (!job.tags.any(tags.contains)) continue;

      final agreed =
          job.agreedFare != null && job.status != JobStatus.cancelled;
      final fare = agreed ? job.agreedFare : job.startingFare;
      if (fare == null || fare <= 0) continue;

      found.add(
        FareComparable(
          fare: fare,
          agreed: agreed,
          tags: job.tags,
          km: near == null ? null : near.distanceTo(job.location) / 1000,
          title: job.title,
          area: job.area,
          daysAgo: now.difference(job.createdAt).inDays.clamp(0, 100000),
        ),
      );
    }

    found.sort((a, b) {
      if (a.agreed != b.agreed) return a.agreed ? -1 : 1;
      final byDistance = (a.km ?? double.infinity).compareTo(
        b.km ?? double.infinity,
      );
      return byDistance != 0 ? byDistance : a.daysAgo.compareTo(b.daysAgo);
    });

    return found.length > limit ? found.sublist(0, limit) : found;
  }
}

/// What the evidence says, in three numbers.
class FareRange {
  const FareRange({
    required this.low,
    required this.typical,
    required this.high,
    required this.agreedCount,
    required this.askedCount,
  });

  /// The quartiles and the median, rounded the way work is priced.
  final int low;
  final int typical;
  final int high;

  /// How many agreed fares this rests on. Zero means there were none, and the
  /// range was built from what hirers asked instead — said so on screen.
  final int agreedCount;
  final int askedCount;

  /// Built from agreed fares where there are any, asked fares where not, and
  /// null where there is nothing at all. Never a blend: an asked fare is a
  /// different kind of number, and averaging it in would let hope pull the
  /// market about.
  static FareRange? of(List<FareComparable> evidence) {
    final agreed = [
      for (final e in evidence)
        if (e.agreed) e.fare,
    ];
    final asked = [
      for (final e in evidence)
        if (!e.agreed) e.fare,
    ];
    final basis = agreed.isNotEmpty ? agreed : asked;
    if (basis.isEmpty) return null;

    basis.sort();
    return FareRange(
      low: FareGuard.roundFare(FareGuard.percentile(basis, 0.25)),
      typical: FareGuard.roundFare(FareGuard.percentile(basis, 0.5)),
      high: FareGuard.roundFare(FareGuard.percentile(basis, 0.75)),
      agreedCount: agreed.length,
      askedCount: asked.length,
    );
  }

  /// The baseline the fare agent's guard holds it to. `sample` counts agreed
  /// fares only, so a range built from asked fares never clamps anything.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'low': low,
    'typical': typical,
    'high': high,
    'sample': agreedCount,
  };
}
