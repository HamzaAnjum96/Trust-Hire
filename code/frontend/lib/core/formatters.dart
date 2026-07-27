import 'package:intl/intl.dart';

import '../models/job.dart';

/// Human-readable formatting for distance and time.
///
/// Wording follows section 19 of the brand guidelines: familiar words, no
/// system language, and approximate rather than precise where precision would
/// be false ("about 2 km away", not "1,987 m").
class Format {
  const Format._();

  /// Distance from the viewer to a job, phrased approximately.
  static String distance(double metres) {
    if (metres < 100) return 'Very close';
    if (metres < 1000) return '${(metres / 50).round() * 50} m away';
    if (metres < 10000) {
      final km = (metres / 100).round() / 10;
      return '${km.toStringAsFixed(1)} km away';
    }
    return '${(metres / 1000).round()} km away';
  }

  /// The work area a job covers.
  static String radius(double metres) {
    if (metres < 1000) return '${metres.round()} m area';
    final km = (metres / 100).round() / 10;
    return '${km.toStringAsFixed(km.truncateToDouble() == km ? 0 : 1)} km area';
  }

  /// When the work needs to happen, relative to [now] where that reads better.
  static String scheduled(DateTime? time, DateTime now) {
    if (time == null) return 'Any time';

    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final dayDifference = day.difference(today).inDays;
    final clock = DateFormat.jm().format(time);

    if (dayDifference == 0) return 'Today, $clock';
    if (dayDifference == 1) return 'Tomorrow, $clock';
    if (dayDifference == -1) return 'Yesterday, $clock';
    if (dayDifference > 1 && dayDifference < 7) {
      return '${DateFormat.EEEE().format(time)}, $clock';
    }
    if (dayDifference < 0) return 'Was ${DateFormat.MMMd().format(time)}';
    return '${DateFormat.MMMd().format(time)}, $clock';
  }

  /// Short form for map markers and dense list rows.
  static String scheduledShort(DateTime? time, DateTime now) {
    if (time == null) return 'Any time';

    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final dayDifference = day.difference(today).inDays;
    final clock = DateFormat.jm().format(time);

    if (dayDifference == 0) return clock;
    if (dayDifference == 1) return 'Tomorrow $clock';
    return DateFormat.MMMd().format(time);
  }

  /// How long ago a job was posted.
  static String posted(DateTime createdAt, DateTime now) {
    final elapsed = now.difference(createdAt);

    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
    if (elapsed.inHours < 24) {
      final h = elapsed.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (elapsed.inDays < 7) {
      final d = elapsed.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }
    return DateFormat.MMMd().format(createdAt);
  }

  /// Playback position or recording length, as m:ss.
  static String duration(Duration? value) {
    if (value == null) return '0:00';
    final minutes = value.inMinutes;
    final seconds = value.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Distance from a viewer position to a job, or null when the viewer's
  /// location is unknown.
  static String? distanceToJob(JobLocation? from, Job job) {
    if (from == null) return null;
    return distance(from.distanceTo(job.location));
  }
}
