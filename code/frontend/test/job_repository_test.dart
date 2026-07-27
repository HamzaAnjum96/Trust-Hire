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

    final original = (await repository.fetchJobs())
        .firstWhere((j) => j.id == 'seed-004');
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
