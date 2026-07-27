import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/models/job.dart';
import 'package:trust_hire/services/job_repository.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/services/media_store.dart';

import 'support/seed_facts.dart';

/// The technical constraints in the sprint plan hinge on this class: seed on
/// first run, then edit the local copy only, with no network anywhere.
void main() {
  testWidgets('the seed loads inside a widget test, however big it gets', (
    tester,
  ) async {
    // A regression guard for a trap that cost an afternoon. `loadString`
    // hands any asset over 50 KB to a background isolate via `compute()`, and
    // that isolate's result never arrives inside `testWidgets` — its
    // fake-async zone does not run it. The seed crossed 50 KB when it went
    // national, and every widget test that touched it hung until the harness
    // gave up with "Cannot close sink while adding stream", which names
    // nothing useful.
    //
    // The size assertion is the point: this test only proves anything while
    // the asset is over the threshold, so it says so out loud rather than
    // passing quietly on a small file some day.
    final bytes = await rootBundle.load('assets/seed/jobs.json');
    expect(
      bytes.lengthInBytes,
      greaterThan(50 * 1024),
      reason: 'below 50 KB this test proves nothing — loadString would work',
    );

    final store = await LocalStore.open();
    final repository = JobRepository(store, MediaStore(store));

    // Deadlocks rather than fails if anyone reaches for loadString again.
    await repository.ensureSeeded();

    expect(await repository.fetchJobs(), isNotEmpty);
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    // rootBundle caches the Future for each asset. Across tests that
    // Future belongs to a previous test's async zone and never
    // completes again, so clear the cache between tests.
    rootBundle.clear();
  });

  Future<JobRepository> buildRepository() async {
    final store = await LocalStore.open();
    return JobRepository(store, MediaStore(store));
  }

  test('seeds local storage on first run', () async {
    final repository = await buildRepository();
    await repository.ensureSeeded();

    final jobs = await repository.fetchJobs();
    expect(jobs, hasLength(await SeedFacts.jobCount()));

    final users = await repository.fetchUsers();
    expect(users, hasLength(await SeedFacts.userCount()));
  });

  test('does not reseed over local changes on a later run', () async {
    final store = await LocalStore.open();
    final repository = JobRepository(store, MediaStore(store));

    final seeded = await SeedFacts.jobCount();

    await repository.ensureSeeded();
    await repository.deleteJob('seed-001');
    expect(await repository.fetchJobs(), hasLength(seeded - 1));

    // A fresh repository over the same store stands in for a relaunch.
    await JobRepository(store, MediaStore(store)).ensureSeeded();
    expect(await repository.fetchJobs(), hasLength(seeded - 1));
  });

  test('saves a new job and returns it newest first', () async {
    final repository = await buildRepository();
    await repository.ensureSeeded();

    final job = Job(
      id: 'local-001',
      location: const JobLocation(latitude: 31.52, longitude: 74.35),
      createdAt: DateTime.now().add(const Duration(minutes: 1)),
      title: 'Fix the gate',
      isLocal: true,
    );
    await repository.saveJob(job);

    final jobs = await repository.fetchJobs();
    expect(jobs, hasLength(await SeedFacts.jobCount() + 1));
    expect(jobs.first.id, 'local-001');
    expect(jobs.first.isLocal, isTrue);
  });

  test('updates an existing job rather than duplicating it', () async {
    final repository = await buildRepository();
    await repository.ensureSeeded();

    final original = (await repository.fetchJobs()).firstWhere(
      (j) => j.id == 'seed-004',
    );
    await repository.saveJob(original.copyWith(title: 'AC still not cooling'));

    final jobs = await repository.fetchJobs();
    expect(jobs, hasLength(await SeedFacts.jobCount()));
    expect(
      jobs.firstWhere((j) => j.id == 'seed-004').title,
      'AC still not cooling',
    );
  });

  test('restores the seed data on reset', () async {
    final repository = await buildRepository();
    await repository.ensureSeeded();
    final seeded = await SeedFacts.jobCount();

    await repository.deleteJob('seed-001');
    await repository.deleteJob('seed-002');
    expect(await repository.fetchJobs(), hasLength(seeded - 2));

    await repository.resetToSeed();
    expect(await repository.fetchJobs(), hasLength(seeded));
  });

  test('reseeds when the store is emptied out from under it', () async {
    final store = await LocalStore.open();
    final repository = JobRepository(store, MediaStore(store));
    await repository.ensureSeeded();

    await store.clear();

    // fetchJobs recovers rather than showing an empty map.
    expect(await repository.fetchJobs(), hasLength(await SeedFacts.jobCount()));
  });
}
