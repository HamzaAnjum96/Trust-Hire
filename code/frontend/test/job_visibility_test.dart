import 'package:flutter_test/flutter_test.dart';
import 'package:trust_hire/features/feed/job_visibility.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/models/worker_profile.dart';

/// The rule the marketplace rests on (Section 8): a job reaches a worker only
/// when a job tag overlaps a worker tag **and** the job is within reach.
///
/// It is worth testing this hard. Too strict and workers lose income they
/// cannot see they are losing; too loose and the "everyone bids on everything,
/// then cancels" problem the tag system exists to solve comes straight back.
void main() {
  const visibility = JobVisibility();
  final now = DateTime(2026, 7, 27, 10);

  // F-7, Islamabad.
  const islamabad = JobLocation(latitude: 33.7104, longitude: 73.0551);
  // Saddar, Rawalpindi — about 17 km away, so outside the 12 km default.
  const rawalpindi = JobLocation(latitude: 33.5977, longitude: 73.0479);
  // Muzaffarabad — a different city entirely.
  const muzaffarabad = JobLocation(latitude: 34.3700, longitude: 73.4711);

  Job job({
    Set<JobTag> tags = const {JobTag.misc},
    JobLocation location = islamabad,
    double? geofenceMetres,
    bool openToAllLocations = false,
    String id = 'j1',
  }) {
    return Job(
      id: id,
      location: location,
      createdAt: now,
      tags: tags,
      geofenceMetres: geofenceMetres,
      openToAllLocations: openToAllLocations,
    );
  }

  WorkerProfile worker({Set<JobTag>? tags}) =>
      WorkerProfile(userId: 'w1', tags: tags);

  group('tag overlap', () {
    test('a specialty job never reaches a worker on the default tag', () {
      // The single most important assertion in this file. A lawyer's job
      // showing up in a labourer's feed is exactly the failure Section 8
      // names, and the "she cannot do it, so she should not see it" call is
      // what makes the rest of the marketplace behave.
      final legal = job(tags: {JobTag.legal});

      expect(
        visibility.isVisibleTo(legal, worker: worker(), from: islamabad),
        isFalse,
      );
      expect(
        visibility.explain(legal, worker: worker(), from: islamabad),
        VisibilityFailure.noTagOverlap,
      );
    });

    test('opting into the trade is what lets it through', () {
      final legal = job(tags: {JobTag.legal});
      final lawyer = worker(tags: {JobTag.legal});

      expect(
        visibility.isVisibleTo(legal, worker: lawyer, from: islamabad),
        isTrue,
      );
    });

    test('a general job reaches everyone, specialists included', () {
      // A plumber must not stop seeing general work simply by saying she is a
      // plumber. Losing that would quietly take income away from the people
      // who specialised.
      final general = job(tags: {JobTag.misc});
      final plumber = worker(tags: {JobTag.plumbing});

      expect(
        visibility.isVisibleTo(general, worker: plumber, from: islamabad),
        isTrue,
      );
    });

    test('one shared tag out of three is enough', () {
      final mixed = job(tags: {JobTag.masonry, JobTag.construction});
      final mason = worker(tags: {JobTag.construction});

      expect(
        visibility.isVisibleTo(mixed, worker: mason, from: islamabad),
        isTrue,
      );
    });

    test('a job with no tags at all reaches nobody', () {
      // Only jobs written by the POC can be in this state. Showing them to
      // everybody would be the more forgiving choice, but it would also mean
      // the one category of job nobody can filter is the untagged one.
      final orphan = job(tags: const {});

      expect(
        visibility.isVisibleTo(orphan, worker: worker(), from: islamabad),
        isFalse,
      );
      expect(
        visibility.explain(orphan, worker: worker(), from: islamabad),
        VisibilityFailure.noTagOverlap,
      );
    });
  });

  group('the geofence', () {
    test('a nearby job is visible', () {
      expect(
        visibility.isVisibleTo(job(), worker: worker(), from: islamabad),
        isTrue,
      );
    });

    test('a job in another city is not', () {
      final faraway = job(location: muzaffarabad);

      expect(
        visibility.isVisibleTo(faraway, worker: worker(), from: islamabad),
        isFalse,
      );
      expect(
        visibility.explain(faraway, worker: worker(), from: islamabad),
        VisibilityFailure.tooFar,
      );
    });

    test('the default reach is the middle of the 10–15 km Section 6 gives', () {
      expect(const JobVisibility().defaultRadiusMetres, 12000);

      // Rawalpindi from Islamabad sits outside 12 km but inside 20 km, which
      // is what makes it a useful boundary case for the twin cities.
      final across = job(location: rawalpindi);
      expect(
        visibility.isVisibleTo(across, worker: worker(), from: islamabad),
        isFalse,
      );
      expect(
        const JobVisibility(
          defaultRadiusMetres: 20000,
        ).isVisibleTo(across, worker: worker(), from: islamabad),
        isTrue,
      );
    });

    test('a job can widen or narrow its own reach', () {
      final wide = job(location: rawalpindi, geofenceMetres: 25000);
      final narrow = job(geofenceMetres: 500);

      expect(
        visibility.isVisibleTo(wide, worker: worker(), from: islamabad),
        isTrue,
      );
      expect(
        visibility.isVisibleTo(narrow, worker: worker(), from: rawalpindi),
        isFalse,
      );
    });

    test('work that needs no travel ignores distance entirely', () {
      // Section 6: remote work, such as legal advice or tutoring by phone.
      final remote = job(
        tags: {JobTag.legal},
        location: islamabad,
        openToAllLocations: true,
      );

      expect(
        visibility.isVisibleTo(
          remote,
          worker: worker(tags: {JobTag.legal}),
          from: muzaffarabad,
        ),
        isTrue,
      );
    });

    test('tags still apply to work open to everywhere', () {
      // Open to all locations is not open to all workers.
      final remote = job(tags: {JobTag.legal}, openToAllLocations: true);

      expect(
        visibility.isVisibleTo(remote, worker: worker(), from: muzaffarabad),
        isFalse,
      );
    });

    test('an unknown position stands the geofence down, not the feed', () {
      // A worker who declined location should lose sorting, not lose work.
      final faraway = job(location: muzaffarabad);

      expect(visibility.isVisibleTo(faraway, worker: worker()), isTrue);
      expect(visibility.explain(faraway, worker: worker()), isNull);
    });

    test('an unknown position does not bypass the tag rule', () {
      expect(
        visibility.isVisibleTo(job(tags: {JobTag.legal}), worker: worker()),
        isFalse,
      );
    });
  });

  group('the feed', () {
    final jobs = [
      job(id: 'near-general'),
      job(id: 'near-legal', tags: {JobTag.legal}),
      job(id: 'far-general', location: muzaffarabad),
      job(id: 'remote-legal', tags: {JobTag.legal}, openToAllLocations: true),
      job(id: 'near-plumbing', tags: {JobTag.plumbing}),
    ];

    test('a general worker sees only nearby general work', () {
      final feed = visibility.feedFor(jobs, worker: worker(), from: islamabad);

      expect(feed.map((j) => j.id), ['near-general']);
    });

    test('adding a trade widens the feed without narrowing it', () {
      final before = visibility.feedFor(
        jobs,
        worker: worker(),
        from: islamabad,
      );
      final after = visibility.feedFor(
        jobs,
        worker: worker(tags: {JobTag.legal}),
        from: islamabad,
      );

      expect(after.map((j) => j.id), containsAll(before.map((j) => j.id)));
      expect(
        after.map((j) => j.id),
        containsAll(['near-legal', 'remote-legal']),
      );
      expect(after, hasLength(3));
    });

    test('explain returns null exactly when the job is in the feed', () {
      for (final j in jobs) {
        final visible = visibility.isVisibleTo(
          j,
          worker: worker(tags: {JobTag.legal}),
          from: islamabad,
        );
        final reason = visibility.explain(
          j,
          worker: worker(tags: {JobTag.legal}),
          from: islamabad,
        );

        expect(reason == null, visible, reason: j.id);
      }
    });

    test('a missing tag is reported ahead of distance', () {
      // Both are wrong with this one; the tag is the one the worker can do
      // something about, so it is the one to say.
      final far = job(tags: {JobTag.legal}, location: muzaffarabad);

      expect(
        visibility.explain(far, worker: worker(), from: islamabad),
        VisibilityFailure.noTagOverlap,
      );
    });
  });

  group('the worker profile', () {
    test('starts on the default tag with no decision to make', () {
      expect(worker().tags, JobTag.defaultWorkerTags);
      expect(worker().isSpecialised, isFalse);
    });

    test('adding a trade keeps the default', () {
      final plumber = worker().withTag(JobTag.plumbing);

      expect(plumber.tags, {JobTag.misc, JobTag.plumbing});
      expect(plumber.specialities, {JobTag.plumbing});
      expect(plumber.isSpecialised, isTrue);
    });

    test('a trade can be dropped again', () {
      final plumber = worker().withTag(JobTag.plumbing);

      expect(
        plumber.withoutTag(JobTag.plumbing).tags,
        JobTag.defaultWorkerTags,
      );
    });

    test('the default tag cannot be dropped', () {
      // A worker with no tags would have an empty feed forever, and would have
      // no way to work out why.
      final stripped = worker(tags: {JobTag.plumbing}).withoutTag(JobTag.misc);

      expect(stripped.tags, contains(JobTag.misc));
    });

    test('the default is restored even if storage lost it', () {
      final restored = WorkerProfile.fromJson({
        'userId': 'w1',
        'tags': ['plumbing'],
      });

      expect(restored.tags, {JobTag.misc, JobTag.plumbing});
    });

    test('round-trips through JSON with its trust signals', () {
      final profile = WorkerProfile(
        userId: 'w1',
        tags: {JobTag.plumbing},
        completedJobs: 14,
        averageFare: 2350,
        rating: 4.6,
      );

      final restored = WorkerProfile.fromJson(profile.toJson());
      expect(restored.userId, 'w1');
      expect(restored.tags, {JobTag.misc, JobTag.plumbing});
      expect(restored.completedJobs, 14);
      expect(restored.averageFare, 2350);
      expect(restored.rating, 4.6);
    });

    test('an unknown tag in storage does not lose the rest of the profile', () {
      final restored = WorkerProfile.fromJson({
        'userId': 'w1',
        'tags': ['plumbing', 'quantum_plumbing'],
        'completedJobs': 3,
      });

      expect(restored.tags, {JobTag.misc, JobTag.plumbing});
      expect(restored.completedJobs, 3);
    });
  });

  group('roles', () {
    test('ids survive a round trip', () {
      for (final role in UserRole.values) {
        expect(UserRole.fromId(role.id), role);
      }
    });

    test('an unknown role reads as worker', () {
      // The useful default rather than the cautious one: a worker's home is a
      // feed of real jobs, where a hirer's is an empty list of their own
      // postings. Defaulting to the empty screen would make a working app
      // look broken, and the feed shows nothing a map did not already.
      expect(UserRole.fromId('administrator'), UserRole.worker);
      expect(UserRole.fromId(null), UserRole.worker);
    });
  });
}
