import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/job.dart';
import '../services/job_repository.dart';

/// Loading state for the job list, so screens can show honest loading, empty
/// and error states rather than an ambiguous blank surface.
enum LoadState { idle, loading, ready, failed }

/// Holds the jobs in memory and mediates every change to them.
///
/// Deliberately a plain [ChangeNotifier] — the POC does not need a heavier
/// state management library, and this keeps the data flow easy to follow.
class JobController extends ChangeNotifier {
  JobController(this._repository);

  final JobRepository _repository;

  List<Job> _jobs = const <Job>[];
  List<AppUser> _users = const <AppUser>[];
  LoadState _state = LoadState.idle;

  List<Job> get jobs => _jobs;
  List<AppUser> get users => _users;
  LoadState get state => _state;

  bool get isLoading => _state == LoadState.loading;
  bool get hasFailed => _state == LoadState.failed;

  /// Seeds on first run, then loads everything from local storage.
  Future<void> load() async {
    _state = LoadState.loading;
    notifyListeners();

    try {
      await _repository.ensureSeeded();
      _jobs = await _repository.fetchJobs();
      _users = await _repository.fetchUsers();
      _state = LoadState.ready;
    } catch (error) {
      // The screen supplies the wording. A controller has no BuildContext, so
      // any message written here would be English in an Urdu interface — and
      // it would win over the screen's fallback rather than being overridden
      // by it.
      _state = LoadState.failed;
      if (kDebugMode) {
        debugPrint('JobController.load failed: $error');
      }
    }

    notifyListeners();
  }

  Job? jobById(String id) {
    for (final job in _jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  AppUser? userById(String? id) {
    if (id == null) return null;
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  Future<void> saveJob(Job job) async {
    await _repository.saveJob(job);
    _jobs = await _repository.fetchJobs();
    notifyListeners();
  }

  Future<void> deleteJob(String id) async {
    await _repository.deleteJob(id);
    _jobs = await _repository.fetchJobs();
    notifyListeners();
  }

  /// Discards everything created on this device and restores the seed data.
  Future<void> resetToSeed() async {
    _state = LoadState.loading;
    notifyListeners();

    await _repository.resetToSeed();
    _jobs = await _repository.fetchJobs();
    _users = await _repository.fetchUsers();
    _state = LoadState.ready;
    notifyListeners();
  }
}
