import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/admin.dart';
import '../models/app_user.dart';
import '../models/bid.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../models/job_tag.dart';
import '../models/premium.dart';
import '../models/rating.dart';
import '../models/wallet.dart';
import '../models/worker_profile.dart';

/// Loads the startup JSON bundled in `assets/seed/`.
///
/// Per the sprint plan's technical constraints, the app copies these files into
/// local storage on first run and then edits only the local copy. Seed times
/// are stored as day offsets rather than absolute dates so the demo data stays
/// plausibly "today" and "tomorrow" however long after packaging it is run.
class SeedLoader {
  const SeedLoader();

  static const _jobsAsset = 'assets/seed/jobs.json';
  static const _usersAsset = 'assets/seed/users.json';
  static const _bidsAsset = 'assets/seed/bids.json';
  static const _ratingsAsset = 'assets/seed/ratings.json';
  static const _accountsAsset = 'assets/seed/accounts.json';
  static const _directoryAsset = 'assets/seed/directory.json';
  static const _reviewsAsset = 'assets/seed/reviews.json';
  static const _cnicsAsset = 'assets/seed/cnics.json';
  static const _disputesAsset = 'assets/seed/disputes.json';

  Future<List<Job>> loadJobs() async {
    final decoded = await _readJson(_jobsAsset) as List<dynamic>;
    final now = DateTime.now();

    return decoded
        .cast<Map<String, dynamic>>()
        .map((json) => _jobFromSeed(json, now))
        .toList(growable: false);
  }

  Future<List<AppUser>> loadUsers() async {
    final decoded = await _readJson(_usersAsset) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(AppUser.fromJson)
        .toList(growable: false);
  }

  /// Offers on the seeded jobs — waiting, accepted and passed over.
  ///
  /// Without these a demonstration could reach the bidding screen but never a
  /// hirer with a choice to make, and never a worker looking at an offer that
  /// went to somebody else.
  Future<List<Bid>> loadBids() async {
    final decoded = await _readJson(_bidsAsset) as List<dynamic>;
    final now = DateTime.now();

    return decoded.cast<Map<String, dynamic>>().map((json) {
      return Bid(
        id: json['id'] as String,
        jobId: json['jobId'] as String,
        workerId: json['workerId'] as String,
        fare: (json['fare'] as num).round(),
        createdAt: _ago(json, now),
        message: json['message'] as String?,
        status: BidStatus.fromId(json['status'] as String?),
      );
    }).toList(growable: false);
  }

  Future<List<Rating>> loadRatings() async {
    final decoded = await _readJson(_ratingsAsset) as List<dynamic>;
    final now = DateTime.now();

    return decoded.cast<Map<String, dynamic>>().map((json) {
      return Rating(
        id: json['id'] as String,
        jobId: json['jobId'] as String,
        side: RatedSide.fromId(json['side'] as String?),
        stars: (json['stars'] as num).round(),
        createdAt: _ago(json, now),
        note: json['note'] as String?,
      );
    }).toList(growable: false);
  }

  /// The state that belongs to a person rather than to a job: which side of
  /// the marketplace they are on, the trades they have opted into, and their
  /// wallet.
  Future<List<SeededAccount>> loadAccounts() async {
    final decoded = await _readJson(_accountsAsset) as List<dynamic>;
    final now = DateTime.now();

    return decoded.cast<Map<String, dynamic>>().map((json) {
      final id = json['id'] as String;

      return SeededAccount(
        id: id,
        role: UserRole.fromId(json['role'] as String?),
        profile: WorkerProfile(
          userId: id,
          tags: (json['trades'] as List<dynamic>? ?? const [])
              .map((tag) => JobTag.fromId(tag as String?))
              .whereType<JobTag>()
              .toSet(),
        ),
        wallet: Wallet(
          userId: id,
          entries: (json['wallet'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()
              .map(
                (entry) => WalletEntry(
                  id: entry['id'] as String,
                  kind: WalletEntryKind.fromId(entry['kind'] as String?),
                  tokens: (entry['tokens'] as num).round(),
                  createdAt: _ago(entry, now),
                  jobId: entry['jobId'] as String?,
                ),
              )
              .toList(),
        ),
      );
    }).toList(growable: false);
  }

  /// The Mode B directory: who is listed, what they charge, and until when.
  ///
  /// Subscription dates are relative like everything else here. A listing that
  /// expired on the day the demo was packaged would show the whole directory
  /// as lapsed a month later, which is the one state Section 9 wants to be
  /// rare.
  Future<List<DirectoryListing>> loadDirectory() async {
    final decoded = await _readJson(_directoryAsset) as List<dynamic>;
    final now = DateTime.now();

    return decoded.cast<Map<String, dynamic>>().map((json) {
      // **Turn the relative dates absolute, then hand the whole thing to the
      // model.** This used to rebuild the listing field by field, which meant
      // the seed had a second, hand-written copy of `fromJson` that nobody
      // updated when the model grew — `base` was added, the directory kept
      // loading, and every seeded worker silently had no location. The same
      // shape as `loadReviews` below, for the same reason.
      final subscription = json['subscription'] as Map<String, dynamic>?;

      return DirectoryListing.fromJson({
        ...json,
        if (subscription != null)
          'subscription': <String, dynamic>{
            ...subscription,
            'startedAt': now
                .subtract(
                  Duration(
                    days: (subscription['startedDaysAgo'] as num?)?.round() ?? 0,
                  ),
                )
                .toIso8601String(),
            'expiresAt': now
                .add(
                  Duration(
                    days: (subscription['endsInDays'] as num?)?.round() ?? 0,
                  ),
                )
                .toIso8601String(),
          },
      });
    }).toList(growable: false);
  }

  /// Where each account stands with the platform, for the admin queue.
  Future<List<AccountReview>> loadReviews() async {
    final decoded = await _readJson(_reviewsAsset) as List<dynamic>;
    final now = DateTime.now();

    return decoded.cast<Map<String, dynamic>>().map((json) {
      // The seed stores *how long ago*, like every other dated thing in it, so
      // a demo installed today reads as recent rather than as a snapshot of
      // whenever the generator last ran.
      return AccountReview.fromJson({
        ...json,
        if (json['cnicDaysAgo'] != null)
          'cnicSubmittedAt': _daysAgo(now, json['cnicDaysAgo']),
        if (json['phoneDaysAgo'] != null)
          'phoneVerifiedAt': _daysAgo(now, json['phoneDaysAgo']),
      });
    }).toList(growable: false);
  }

  static String _daysAgo(DateTime now, Object? days) =>
      now.subtract(Duration(days: (days as num).round())).toIso8601String();

  Future<List<CnicRecord>> loadCnics() async {
    final decoded = await _readJson(_cnicsAsset) as List<dynamic>;
    final now = DateTime.now();

    return decoded.cast<Map<String, dynamic>>().map((json) {
      return CnicRecord(
        userId: json['userId'] as String,
        maskedNumber: json['maskedNumber'] as String,
        nameOnCard: json['nameOnCard'] as String,
        submittedAt: now.subtract(
          Duration(days: (json['submittedDaysAgo'] as num?)?.round() ?? 0),
        ),
      );
    }).toList(growable: false);
  }

  Future<List<Dispute>> loadDisputes() async {
    final decoded = await _readJson(_disputesAsset) as List<dynamic>;
    final now = DateTime.now();

    return decoded.cast<Map<String, dynamic>>().map((json) {
      return Dispute(
        id: json['id'] as String,
        jobId: json['jobId'] as String,
        aboutUserId: json['aboutUserId'] as String,
        raisedByUserId: json['raisedByUserId'] as String,
        raisedAt: _ago(json, now, key: 'raisedHoursAgo'),
        reason: json['reason'] as String,
      );
    }).toList(growable: false);
  }

  /// Resolves a seed file's `hoursAgo` against [now].
  ///
  /// Relative like the job times, and for the same reason: a wallet whose last
  /// entry is dated whenever the demo was packaged reads as abandoned.
  DateTime _ago(
    Map<String, dynamic> json,
    DateTime now, {
    String key = 'hoursAgo',
  }) => now.subtract(
    Duration(minutes: (((json[key] as num?)?.toDouble() ?? 0) * 60).round()),
  );

  /// Reads and decodes a bundled JSON asset.
  ///
  /// Deliberately **not** `rootBundle.loadString`. That method hands anything
  /// over 50 KB to a background isolate via `compute()` to keep the decode off
  /// the main thread — sensible on a device, and a deadlock inside
  /// `testWidgets`, whose fake-async zone never lets the isolate's result come
  /// back. The seed crossed 50 KB when it went national, and every widget test
  /// that touched it hung until the harness gave up.
  ///
  /// Decoding a hundred kilobytes of JSON synchronously costs a few
  /// milliseconds once, on first run only, which is a price worth paying to
  /// keep the data loadable from a test.
  Future<Object?> _readJson(String asset) async {
    final bytes = await rootBundle.load(asset);
    return jsonDecode(
      utf8.decode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
  }

  /// Resolves the relative day/hour offsets in the seed file into concrete
  /// timestamps anchored to [now].
  Job _jobFromSeed(Map<String, dynamic> json, DateTime now) {
    final scheduled = _resolveScheduled(json, now);
    final createdHoursAgo = (json['createdHoursAgo'] as num?)?.toDouble() ?? 24;

    final durationSeconds = (json['voiceNoteSeconds'] as num?)?.toDouble();

    return Job(
      id: json['id'] as String,
      location: JobLocation.fromJson(json['location'] as Map<String, dynamic>),
      createdAt: now.subtract(
        Duration(minutes: (createdHoursAgo * 60).round()),
      ),
      title: json['title'] as String?,
      // Seed files may give a single `type` or a `tags` list; both are read
      // so the demo data did not have to be rewritten wholesale.
      tags:
          ((json['tags'] as List<dynamic>?) ??
                  [if (json['type'] != null) json['type']])
              .map((id) => JobTag.fromId(id as String?))
              .whereType<JobTag>()
              .toSet(),
      // The generator writes the neighbourhood and the city separately; the
      // app only ever shows them together.
      area: json['area'] == null ? null : '${json['area']}, ${json['city']}',
      startingFare: (json['startingFare'] as num?)?.round(),
      geofenceMetres: (json['geofenceMetres'] as num?)?.toDouble(),
      openToAllLocations: json['openToAllLocations'] as bool? ?? false,
      radiusMetres: (json['radiusMetres'] as num?)?.toDouble() ?? 1000,
      scheduledTime: scheduled,
      voiceNotePath: json['voiceNote'] as String?,
      voiceNoteDuration: durationSeconds == null
          ? null
          : Duration(milliseconds: (durationSeconds * 1000).round()),
      photoPaths:
          (json['photos'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      shortDescription: json['shortDescription'] as String?,
      contactNumber: json['contact'] as String?,
      postedBy: json['postedBy'] as String?,
      status: JobStatus.fromId(json['status'] as String?),
      acceptedWorkerId: json['acceptedWorkerId'] as String?,
      agreedFare: (json['agreedFare'] as num?)?.round(),
      isLocal: false,
    );
  }

  DateTime? _resolveScheduled(Map<String, dynamic> json, DateTime now) {
    final dayOffset = json['scheduledDayOffset'] as int?;
    if (dayOffset == null) return null;

    final hour = (json['scheduledHour'] as num?)?.toInt() ?? 9;
    final minute = (json['scheduledMinute'] as num?)?.toInt() ?? 0;

    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: dayOffset));
    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}

/// One demo account's stored state, as the seed describes it.
///
/// A record rather than three parallel lists, because the three are written
/// together and a wallet that landed without the trades beside it would give a
/// worker a balance and an empty feed.
class SeededAccount {
  const SeededAccount({
    required this.id,
    required this.role,
    required this.profile,
    required this.wallet,
  });

  final String id;
  final UserRole role;
  final WorkerProfile profile;
  final Wallet wallet;
}
