import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/features/feed/job_visibility.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/models/job_tag.dart';
import 'package:trust_hire/models/worker_profile.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';

import 'support/seed_facts.dart';

/// The seed went from sixteen jobs around the twin cities to a national
/// dataset, and that change is only worth anything if the app behaves
/// sensibly at the new size. These are the properties that make it a *useful*
/// demo rather than a big one: real spread, no duplicate-looking rows, and a
/// worker in one city not being shown work in another.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  Future<List<Job>> seeded() async {
    final store = await LocalStore.open();
    final repository = JobRepository(store, MediaStore(store));
    await repository.ensureSeeded();
    return repository.fetchJobs();
  }

  group('the shape of the data', () {
    test('covers the country, not one metro', () async {
      final jobs = await seeded();

      expect(jobs.length, greaterThan(100));

      // Corner to corner. Karachi to Gilgit is about 1,500 km; anything much
      // under a thousand means the data quietly collapsed back to one region.
      final lats = jobs.map((j) => j.location.latitude);
      final lngs = jobs.map((j) => j.location.longitude);
      final span =
          JobLocation(
            latitude: lats.reduce((a, b) => a < b ? a : b),
            longitude: lngs.reduce((a, b) => a < b ? a : b),
          ).distanceTo(
            JobLocation(
              latitude: lats.reduce((a, b) => a > b ? a : b),
              longitude: lngs.reduce((a, b) => a > b ? a : b),
            ),
          );

      expect(
        span,
        greaterThan(1000000),
        reason: 'span is only ${span ~/ 1000} km',
      );
    });

    test('every job says where it is', () async {
      // Without this a row reads "Help needed for a day" and nothing else,
      // which is unusable once the jobs are eight hundred kilometres apart.
      for (final job in await seeded()) {
        expect(job.area, isNotNull, reason: job.id);
        expect(job.area, contains(','), reason: 'expected area and city');
      }
    });

    test('no two jobs sit on exactly the same point', () async {
      // Identical coordinates cluster forever: zooming in never separates
      // them, so the cluster becomes a dead end.
      final jobs = await seeded();
      final points = jobs
          .map((j) => '${j.location.latitude},${j.location.longitude}')
          .toSet();

      expect(points, hasLength(jobs.length));
    });

    test('ids are unique', () async {
      final jobs = await seeded();
      expect(jobs.map((j) => j.id).toSet(), hasLength(jobs.length));
    });

    test('fares vary by trade and by city', () async {
      // A demo where every job quotes the same number looks synthetic, and a
      // fare that ignores the local cost of living is worse than none.
      final jobs = await seeded();
      final fares = jobs
          .where((j) => j.startingFare != null)
          .map((j) => j.startingFare!)
          .toSet();

      expect(fares.length, greaterThan(20));
      expect(fares.reduce((a, b) => a < b ? a : b), greaterThan(0));
    });

    test('the mix keeps every posting style represented', () async {
      final jobs = await seeded();

      expect(jobs.where((j) => j.isAudioOnly), isNotEmpty);
      expect(jobs.where((j) => j.hasPhotos), isNotEmpty);
      expect(jobs.where((j) => j.startingFare == null), isNotEmpty);
      expect(jobs.where((j) => !j.hasContact), isNotEmpty);
      expect(jobs.where((j) => j.openToAllLocations), isNotEmpty);
      expect(jobs.where((j) => j.scheduledTime == null), isNotEmpty);
    });

    test('rows do not read as duplicates of each other', () async {
      // Three "Help needed for a day" in one screenful looks like a bug in
      // the app rather than a coincidence in the data.
      final jobs = await seeded();
      final titles = jobs.map((j) => j.title).whereType<String>().toList();
      final distinct = titles.toSet();

      expect(
        distinct.length / titles.length,
        greaterThan(0.4),
        reason:
            'only ${distinct.length} distinct titles across ${titles.length}',
      );
    });
  });

  group('what a worker actually sees', () {
    const rule = JobVisibility();

    // Neighbourhoods, not city centres, so these sit inside the seeded areas.
    const karachi = JobLocation(latitude: 24.9204, longitude: 67.0971);
    const lahore = JobLocation(latitude: 31.4697, longitude: 74.2728);

    test('a worker in Karachi is not shown work in Lahore', () async {
      final jobs = await seeded();
      final feed = rule.feedFor(
        jobs,
        worker: WorkerProfile(userId: 'w'),
        from: karachi,
      );

      expect(feed, isNotEmpty, reason: 'Karachi should have general work');
      for (final job in feed) {
        // Everything in the feed is either within reach or explicitly remote.
        expect(
          job.openToAllLocations ||
              karachi.distanceTo(job.location) <= rule.defaultRadiusMetres,
          isTrue,
          reason:
              '${job.id} is ${karachi.distanceTo(job.location) ~/ 1000} km away',
        );
      }
    });

    test('the two cities do not see the same jobs', () async {
      final jobs = await seeded();
      final worker = WorkerProfile(userId: 'w');

      final inKarachi = rule
          .feedFor(jobs, worker: worker, from: karachi)
          .where((j) => !j.openToAllLocations)
          .map((j) => j.id)
          .toSet();
      final inLahore = rule
          .feedFor(jobs, worker: worker, from: lahore)
          .where((j) => !j.openToAllLocations)
          .map((j) => j.id)
          .toSet();

      expect(inKarachi, isNotEmpty);
      expect(inLahore, isNotEmpty);
      expect(inKarachi.intersection(inLahore), isEmpty);
    });

    test('a feed is a readable size, not the whole country', () async {
      // The geofence is what makes a national dataset usable. If a worker's
      // feed is hundreds of jobs long, it has stopped doing its job.
      final jobs = await seeded();
      final feed = rule.feedFor(
        jobs,
        worker: WorkerProfile(userId: 'w'),
        from: karachi,
      );

      expect(feed.length, lessThan(jobs.length ~/ 3));
    });

    test('adding a trade widens the feed without leaving the city', () async {
      final jobs = await seeded();
      final general = rule.feedFor(
        jobs,
        worker: WorkerProfile(userId: 'w'),
        from: karachi,
      );
      final plumber = rule.feedFor(
        jobs,
        worker: WorkerProfile(userId: 'w', tags: {JobTag.plumbing}),
        from: karachi,
      );

      expect(plumber.length, greaterThan(general.length));
      expect(
        plumber.map((j) => j.id).toSet(),
        containsAll(general.map((j) => j.id)),
      );
    });
  });

  test('the counts the tests rely on still line up', () async {
    expect(await SeedFacts.jobCount(), greaterThan(100));
    expect(await SeedFacts.generalJobCount(), greaterThan(5));
    expect(
      await SeedFacts.generalJobCount(),
      lessThan(await SeedFacts.jobCount()),
    );
  });
}
