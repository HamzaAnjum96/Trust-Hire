import 'package:flutter/foundation.dart';

import '../../models/job.dart';

/// When the work is needed.
enum TimeFilter {
  any('Any time'),
  today("Today's Jobs"),
  tomorrow('Tomorrow'),
  thisWeek('This week');

  const TimeFilter(this.label);

  final String label;
}

/// How far away the work is. Only meaningful once a position is known.
enum DistanceFilter {
  any('Any distance', null),
  nearMe('Near Me', 2000),
  withinFive('Within 5 km', 5000),
  withinTen('Within 10 km', 10000);

  const DistanceFilter(this.label, this.metres);

  final String label;
  final double? metres;
}

/// A search and filter over the job list.
///
/// Filtering is deliberately forgiving: a job with no scheduled time is not
/// hidden by a time filter unless the user asked for a specific day, because
/// "any time" is a normal state in this product rather than missing data.
@immutable
class JobFilter {
  const JobFilter({
    this.query = '',
    this.time = TimeFilter.any,
    this.distance = DistanceFilter.any,
    this.withVoiceNote = false,
    this.withPhotos = false,
  });

  final String query;
  final TimeFilter time;
  final DistanceFilter distance;
  final bool withVoiceNote;
  final bool withPhotos;

  bool get isActive =>
      query.trim().isNotEmpty ||
      time != TimeFilter.any ||
      distance != DistanceFilter.any ||
      withVoiceNote ||
      withPhotos;

  /// How many filters are on, for the badge on the filter control.
  int get activeCount => [
    query.trim().isNotEmpty,
    time != TimeFilter.any,
    distance != DistanceFilter.any,
    withVoiceNote,
    withPhotos,
  ].where((on) => on).length;

  JobFilter copyWith({
    String? query,
    TimeFilter? time,
    DistanceFilter? distance,
    bool? withVoiceNote,
    bool? withPhotos,
  }) {
    return JobFilter(
      query: query ?? this.query,
      time: time ?? this.time,
      distance: distance ?? this.distance,
      withVoiceNote: withVoiceNote ?? this.withVoiceNote,
      withPhotos: withPhotos ?? this.withPhotos,
    );
  }

  /// Applies the filter, newest first.
  List<Job> apply(List<Job> jobs, {required DateTime now, JobLocation? from}) {
    return jobs
        .where((job) => _matches(job, now: now, from: from))
        .toList(growable: false);
  }

  bool _matches(Job job, {required DateTime now, JobLocation? from}) {
    if (!_matchesQuery(job)) return false;
    if (!_matchesTime(job, now)) return false;
    if (!_matchesDistance(job, from)) return false;
    if (withVoiceNote && !job.hasVoiceNote) return false;
    if (withPhotos && !job.hasPhotos) return false;
    return true;
  }

  bool _matchesQuery(Job job) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;

    // Search what a person actually wrote, plus the fallback heading so a
    // voice-only job is still findable by "voice".
    final haystack = [
      job.title,
      job.shortDescription,
      job.displayTitle,
    ].whereType<String>().join(' ').toLowerCase();

    // Every word must appear somewhere, so "plumber today" narrows rather
    // than widens.
    return needle
        .split(RegExp(r'\s+'))
        .every((word) => haystack.contains(word));
  }

  bool _matchesTime(Job job, DateTime now) {
    if (time == TimeFilter.any) return true;

    final scheduled = job.scheduledTime;
    // A job with no time could be wanted at any point, including today — so
    // hiding it would lose work the user could actually take.
    if (scheduled == null) return true;

    final startOfToday = DateTime(now.year, now.month, now.day);
    final days = DateTime(
      scheduled.year,
      scheduled.month,
      scheduled.day,
    ).difference(startOfToday).inDays;

    return switch (time) {
      TimeFilter.any => true,
      TimeFilter.today => days == 0,
      TimeFilter.tomorrow => days == 1,
      TimeFilter.thisWeek => days >= 0 && days < 7,
    };
  }

  bool _matchesDistance(Job job, JobLocation? from) {
    final limit = distance.metres;
    if (limit == null) return true;
    // Without a position there is nothing to measure against, so the filter
    // stands down rather than emptying the list.
    if (from == null) return true;

    return from.distanceTo(job.location) <= limit;
  }
}
