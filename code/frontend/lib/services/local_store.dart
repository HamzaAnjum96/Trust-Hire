import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';

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
  ///
  /// Swept by prefix rather than by walking [StoreKeys.all], because two
  /// groups of keys are not enumerable: the media blobs, which are named after
  /// the ids they hold, and the per-account keys, which are named after
  /// whichever demo accounts have been used. Anything the app wrote starts
  /// with [StoreKeys.prefix]; nothing else is touched.
  Future<void> clear() async {
    final ours = _prefs.getKeys().where((key) => key.startsWith(StoreKeys.prefix));
    for (final key in ours.toList(growable: false)) {
      await _prefs.remove(key);
    }
  }
}

/// Keys used by the local store, kept in one place so a reset can enumerate
/// them without clearing unrelated preferences.
class StoreKeys {
  const StoreKeys._();

  /// Every key the app writes begins with this, so a reset can find them all
  /// without leaving anything else in `shared_preferences` behind.
  static const prefix = 'trust_hire.';

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

  /// When each account last opened the notification feed, as a JSON object of
  /// account id to ISO timestamp. One key rather than one per account, because
  /// a reset that has to guess at key names misses the ones it did not guess.
  static const notificationsSeen = 'trust_hire.notifications_seen';

  /// Every message on every job's thread, as a JSON list.
  static const messages = 'trust_hire.messages';

  /// Every rating either side has given, as a JSON list.
  static const ratings = 'trust_hire.ratings';

  /// Which side of the marketplace this device is on — worker or hirer.
  static const role = 'trust_hire.role';

  /// The worker's tag list and trust signals, as a JSON object.
  static const workerProfile = 'trust_hire.worker_profile';

  /// Which demo account the device is currently being.
  static const activeAccount = 'trust_hire.active_account';

  /// Set once the worker has closed the "add a trade" notice. Per account.
  static const tradesNoticeDismissed = 'trust_hire.trades_notice_dismissed';

  /// Every directory listing — subscription, service menu, credentials and
  /// service area — as a JSON list. Shared rather than per account: a
  /// directory only one person can see is not a directory.
  static const directory = 'trust_hire.directory';

  /// Every admin action ever taken, as a JSON list. Append-only in practice —
  /// [AdminController] is the only writer and never removes an entry.
  static const auditLog = 'trust_hire.audit_log';

  /// Where each account stands with the platform, and the Section 2 signals
  /// an approval decision is made on.
  static const accountReviews = 'trust_hire.account_reviews';

  /// Submitted CNICs. Reachable only through an open dispute — see
  /// [AdminRules.mayOpenCnic].
  static const cnicRecords = 'trust_hire.cnic_records';

  /// Complaints about jobs. The only thing that unlocks a CNIC.
  static const disputes = 'trust_hire.disputes';

  /// The verification code outstanding on this account, if any. Per account,
  /// and stored rather than held in memory so that closing the app is not a
  /// way to get a fresh set of guesses.
  static const phoneChallenge = 'trust_hire.phone_challenge';

  /// Local writes the server has not accepted yet.
  ///
  /// Stored rather than held in memory for the obvious reason: the queue exists
  /// because the network is not there, and an app that is closed while offline
  /// would otherwise lose exactly the writes the queue was protecting.
  static const outbox = 'trust_hire.outbox';

  /// The server timestamp of the newest record pulled, so the next pull can
  /// ask for what changed rather than for everything.
  static const lastPulledAt = 'trust_hire.last_pulled_at';

  /// The per-account name for a key.
  ///
  /// Role, trades, saved jobs and the wallet belong to a person rather than to
  /// the device, so each demo account gets its own copy — otherwise switching
  /// to a hirer would hand them the worker's balance and trades, and the
  /// switch would prove nothing.
  ///
  /// The device account deliberately keeps the **unsuffixed** key. It is the
  /// account the app had before the switcher existed, so everything already
  /// stored on somebody's phone is still theirs after an update.
  static String forAccount(String key, String accountId) =>
      accountId == DemoAccounts.deviceId ? key : '$key#$accountId';

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
    ratings,
    role,
    workerProfile,
    activeAccount,
    tradesNoticeDismissed,
    directory,
    auditLog,
    accountReviews,
    cnicRecords,
    disputes,
    phoneChallenge,
    outbox,
    lastPulledAt,
    mediaIndex,
  ];
}
