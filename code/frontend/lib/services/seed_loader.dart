import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/app_user.dart';
import '../models/job.dart';
import '../models/job_type.dart';

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
    final raw = await rootBundle.loadString(_jobsAsset);
    final decoded = jsonDecode(raw) as List<dynamic>;
    final now = DateTime.now();

    return decoded
        .cast<Map<String, dynamic>>()
        .map((json) => _jobFromSeed(json, now))
        .toList(growable: false);
  }

  Future<List<AppUser>> loadUsers() async {
    final raw = await rootBundle.loadString(_usersAsset);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(AppUser.fromJson)
        .toList(growable: false);
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
      type: JobType.fromId(json['type'] as String?),
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
