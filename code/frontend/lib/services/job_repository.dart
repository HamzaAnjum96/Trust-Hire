import '../models/app_user.dart';
import '../models/job.dart';
import 'local_store.dart';
import 'media_store.dart';
import 'seed_loader.dart';

/// Reads and writes jobs against local storage.
///
/// On first run the seed JSON is copied into the store; from then on every
/// read and write goes to the local copy only. There is no network call
/// anywhere in this class — the POC works fully offline by design.
class JobRepository {
  JobRepository(
    this._store,
    this._mediaStore, [
    this._seedLoader = const SeedLoader(),
  ]);

  final LocalStore _store;
  final MediaStore _mediaStore;
  final SeedLoader _seedLoader;

  /// Copies the seed data into local storage if this is a first run.
  ///
  /// Safe to call on every launch — it is a no-op once the seeded flag is set.
  Future<void> ensureSeeded() async {
    if (_store.readFlag(StoreKeys.seeded)) return;
    await resetToSeed();
  }

  /// Discards local changes and restores the bundled seed data.
  Future<void> resetToSeed() async {
    // Photos and recordings made on this device go too, or they would linger
    // in storage with no job referencing them.
    await _mediaStore.clear();

    final jobs = await _seedLoader.loadJobs();
    final users = await _seedLoader.loadUsers();

    await _store.writeCollection(
      StoreKeys.jobs,
      jobs.map((j) => j.toJson()).toList(growable: false),
    );
    await _store.writeCollection(
      StoreKeys.users,
      users.map((u) => u.toJson()).toList(growable: false),
    );
    await _store.writeFlag(StoreKeys.seeded, true);
  }

  /// All jobs, newest first.
  Future<List<Job>> fetchJobs() async {
    final raw = _store.readCollection(StoreKeys.jobs);
    if (raw == null) {
      // Store was cleared or corrupt — reseed rather than showing an empty map.
      await resetToSeed();
      final reseeded = _store.readCollection(StoreKeys.jobs) ?? const [];
      return _decodeJobs(reseeded);
    }
    return _decodeJobs(raw);
  }

  Future<List<AppUser>> fetchUsers() async {
    final raw = _store.readCollection(StoreKeys.users) ?? const [];
    return raw.map(AppUser.fromJson).toList(growable: false);
  }

  Future<void> saveJob(Job job) async {
    final jobs = await fetchJobs();
    final index = jobs.indexWhere((j) => j.id == job.id);

    if (index == -1) {
      jobs.add(job);
    } else {
      jobs[index] = job;
    }

    await _persist(jobs);

    // Editing can drop a photo or replace a recording; the blob it used is
    // then unreferenced and would otherwise sit in storage forever.
    await _pruneMedia(jobs);
  }

  Future<void> deleteJob(String id) async {
    final jobs = await fetchJobs();
    jobs.removeWhere((j) => j.id == id);
    await _persist(jobs);
    await _pruneMedia(jobs);
  }

  /// Drops blobs no job references any more.
  Future<void> _pruneMedia(List<Job> jobs) async {
    final inUse = <String>{};
    for (final job in jobs) {
      inUse.addAll(job.photoPaths);
      if (job.voiceNotePath != null) inUse.add(job.voiceNotePath!);
    }
    await _mediaStore.pruneExcept(inUse);
  }

  Future<void> _persist(List<Job> jobs) async {
    await _store.writeCollection(
      StoreKeys.jobs,
      jobs.map((j) => j.toJson()).toList(growable: false),
    );
  }

  List<Job> _decodeJobs(List<Map<String, dynamic>> raw) {
    final jobs = raw.map(Job.fromJson).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return jobs;
  }
}
