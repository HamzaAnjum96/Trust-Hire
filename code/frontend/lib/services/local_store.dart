import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A small JSON document store backed by `shared_preferences`.
///
/// The sprint plan lists Hive, Isar, SQLite and local JSON as equally
/// acceptable for the POC and states the choice is not important. This is the
/// local-JSON option: it works identically on Android, iOS and web with no
/// native setup, which keeps the POC verifiable in a browser.
///
/// Everything goes through this interface so the storage engine can be swapped
/// for Isar or SQLite post-POC without touching the repositories above it.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs);
  }

  /// Reads a stored list of JSON objects. Returns null when the key has never
  /// been written, which is how callers detect a first run.
  List<Map<String, dynamic>>? readCollection(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.cast<Map<String, dynamic>>();
    } on FormatException {
      // Corrupt payload — treat it as absent so the caller reseeds rather
      // than crashing on launch.
      return null;
    }
  }

  Future<void> writeCollection(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  bool readFlag(String key, {bool fallback = false}) =>
      _prefs.getBool(key) ?? fallback;

  Future<void> writeFlag(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  String? readString(String key) => _prefs.getString(key);

  Future<void> writeString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  /// Clears everything the app has stored. Used by the "reset to seed data"
  /// action in settings.
  Future<void> clear() async {
    for (final key in StoreKeys.all) {
      await _prefs.remove(key);
    }
  }
}

/// Keys used by the local store, kept in one place so a reset can enumerate
/// them without clearing unrelated preferences.
class StoreKeys {
  const StoreKeys._();

  static const jobs = 'trust_hire.jobs';
  static const users = 'trust_hire.users';
  static const seeded = 'trust_hire.seeded';
  static const themeMode = 'trust_hire.theme_mode';
  static const language = 'trust_hire.language';

  /// Ids of jobs the user bookmarked, comma separated.
  static const savedJobs = 'trust_hire.saved_jobs';

  /// Set once the first-run intro has been seen.
  static const introSeen = 'trust_hire.intro_seen';

  /// Every bid on every job, as a JSON list.
  static const bids = 'trust_hire.bids';

  /// The worker's token wallet — the whole ledger, as a JSON object.
  static const wallet = 'trust_hire.wallet';

  /// Which side of the marketplace this device is on — worker or hirer.
  static const role = 'trust_hire.role';

  /// The worker's tag list and trust signals, as a JSON object.
  static const workerProfile = 'trust_hire.worker_profile';

  /// Comma-separated ids of blobs held by [MediaStore]. The blobs themselves
  /// live under `trust_hire.media.<id>` and are enumerated through this index.
  static const mediaIndex = 'trust_hire.media_index';

  static const all = <String>[
    jobs,
    users,
    seeded,
    themeMode,
    language,
    savedJobs,
    introSeen,
    bids,
    wallet,
    role,
    workerProfile,
    mediaIndex,
  ];
}
