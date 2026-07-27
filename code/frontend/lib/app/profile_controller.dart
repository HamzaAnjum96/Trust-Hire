import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../features/feed/job_visibility.dart';
import '../models/account.dart';
import '../models/job.dart';
import '../models/job_tag.dart';
import '../models/worker_profile.dart';
import '../services/local_store.dart';

/// Which side of the marketplace this device is on, and — for a worker — the
/// trades they have opted into.
///
/// One controller rather than two because the two settings are read together
/// on every feed rebuild, and because switching role has to leave the tag list
/// alone: someone who hires a painter today and looks for work tomorrow should
/// not have to re-pick their trades.
class ProfileController extends ChangeNotifier {
  ProfileController(this._store);

  final LocalStore _store;

  /// Which demo account this is the profile of.
  ///
  /// Role and trades are per-account: a hirer who is also a plumber on another
  /// account should not find the plumber's trades attached to their postings.
  String _userId = DemoAccounts.deviceId;
  String get userId => _userId;

  /// Points the controller at another account and reads its role and trades.
  void setAccount(String id) {
    if (_userId == id) return;
    _userId = id;
    _profile = WorkerProfile(userId: id);
    _role = UserRole.worker;
    load();
  }

  String _keyFor(String key) => StoreKeys.forAccount(key, _userId);

  /// The default until the user says otherwise.
  ///
  /// Worker, not hirer: a worker's feed shows the seeded jobs and is
  /// immediately useful, whereas a hirer opens on an empty "my postings" list.
  /// Choosing the emptier of the two as the default would make a first launch
  /// look broken.
  UserRole _role = UserRole.worker;
  UserRole get role => _role;

  bool get isWorker => _role == UserRole.worker;

  WorkerProfile _profile = WorkerProfile(userId: DemoAccounts.deviceId);
  WorkerProfile get profile => _profile;

  Set<JobTag> get tags => _profile.tags;

  /// The trades beyond the default. What the "My trades" screen counts.
  Set<JobTag> get specialities => _profile.specialities;

  void load() {
    _role = UserRole.fromId(_store.readString(_keyFor(StoreKeys.role)));

    final raw = _store.readString(_keyFor(StoreKeys.workerProfile));
    if (raw != null && raw.isNotEmpty) {
      try {
        _profile = WorkerProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } on FormatException {
        // Corrupt payload. A worker back on the default tag still sees
        // general work, which beats failing to launch.
        _profile = WorkerProfile(userId: _userId);
      }
    } else {
      _profile = WorkerProfile(userId: _userId);
    }

    notifyListeners();
  }

  Future<void> setRole(UserRole role) async {
    if (_role == role) return;
    _role = role;
    notifyListeners();

    await _store.writeString(_keyFor(StoreKeys.role), role.id);
  }

  /// Adds or removes a trade. The default tag cannot be removed, so a worker
  /// can never end up with an empty feed and no way to explain it.
  Future<void> toggleTag(JobTag tag) async {
    _profile = _profile.tags.contains(tag)
        ? _profile.withoutTag(tag)
        : _profile.withTag(tag);
    notifyListeners();

    await _persist();
  }

  Future<void> _persist() => _store.writeString(
    _keyFor(StoreKeys.workerProfile),
    jsonEncode(_profile.toJson()),
  );

  /// The jobs this user should be shown, before their own filters.
  ///
  /// This is Section 8's rule, not a filter — the user cannot switch it off,
  /// which is exactly why the empty state has to name it and offer the way
  /// out. Two deliberate exceptions:
  ///
  /// - A **hirer** sees everything. Their map is where they post, not a feed
  ///   of leads, and hiding other people's jobs from it would tell them
  ///   nothing useful.
  /// - A job **you posted** always stays visible. Watching your own job vanish
  ///   the moment you post it reads as a failed save.
  List<Job> visibleTo(List<Job> jobs, {JobLocation? from}) {
    if (!isWorker) return jobs;

    const rule = JobVisibility();
    return jobs
        .where(
          (job) =>
              job.isPostedBy(_userId) ||
              rule.isVisibleTo(job, worker: _profile, from: from),
        )
        .toList(growable: false);
  }
}
