import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/app_user.dart';
import '../models/job.dart';
import '../models/job_tag.dart';

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
