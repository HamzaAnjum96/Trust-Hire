import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/job.dart';

/// Human-readable formatting for distance and time.
///
/// Wording follows section 19 of the brand guidelines: familiar words, no
/// system language, and approximate rather than precise where precision would
/// be false ("about 2 km away", not "1,987 m").
///
/// Every method takes [AppStrings] so the words come from the active language
/// and dates from the matching locale — a distance reading "2 km away" inside
/// an otherwise Urdu screen was the most visible thing left in English.
class Format {
  const Format._();

  /// The locale to format dates and numbers in.
  static String _localeOf(AppStrings strings) => strings.localeName;

  /// A fare, with thousands separated in the reader's language.
  ///
  /// Whole rupees only. The audience does not think about a job in paisa, and
  /// a decimal point would only ever be noise or a mistype.
  static String fare(AppStrings strings, int rupees) {
    final grouped = NumberFormat.decimalPattern(
      _localeOf(strings),
    ).format(rupees);
    return strings.rupees(grouped);
  }

  /// Distance from the viewer to a job, phrased approximately.
  static String distance(AppStrings strings, double metres) {
    if (metres < 100) return strings.veryClose;
    if (metres < 1000) {
      return strings.metresAway((metres / 50).round() * 50);
    }
    if (metres < 10000) {
      final km = (metres / 100).round() / 10;
      return strings.kilometresAway(km.toStringAsFixed(1));
    }
    return strings.kilometresAway('${(metres / 1000).round()}');
  }

  /// The work area a job covers.
  static String radius(AppStrings strings, double metres) {
    if (metres < 1000) return strings.metresArea(metres.round());

    final km = (metres / 100).round() / 10;
    return strings.kilometresArea(
      km.toStringAsFixed(km.truncateToDouble() == km ? 0 : 1),
    );
  }

  /// When the work needs to happen, relative to [now] where that reads better.
  static String scheduled(AppStrings strings, DateTime? time, DateTime now) {
    if (time == null) return strings.anyTime;

    final locale = _localeOf(strings);
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final dayDifference = day.difference(today).inDays;
    final clock = DateFormat.jm(locale).format(time);

    if (dayDifference == 0) return strings.todayAt(clock);
    if (dayDifference == 1) return strings.tomorrowAt(clock);
    if (dayDifference == -1) return strings.yesterdayAt(clock);
    if (dayDifference > 1 && dayDifference < 7) {
      return strings.dayAt(DateFormat.EEEE(locale).format(time), clock);
    }
    if (dayDifference < 0) {
      return strings.wasOn(DateFormat.MMMd(locale).format(time));
    }
    return strings.dayAt(DateFormat.MMMd(locale).format(time), clock);
  }

  /// A calendar date on its own — "12 Aug" — for a subscription's end.
  ///
  /// No clock time: a subscription runs out on a day, and a minute would be
  /// false precision about something the worker cannot act on that finely.
  static String day(AppStrings strings, DateTime date) =>
      DateFormat.MMMd(_localeOf(strings)).format(date);

  /// How long ago a job was posted.
  static String posted(AppStrings strings, DateTime createdAt, DateTime now) {
    final elapsed = now.difference(createdAt);

    if (elapsed.inMinutes < 1) return strings.justNow;
    if (elapsed.inMinutes < 60) return strings.minutesAgo(elapsed.inMinutes);
    if (elapsed.inHours < 24) return strings.hoursAgo(elapsed.inHours);
    if (elapsed.inDays < 7) return strings.daysAgo(elapsed.inDays);

    return DateFormat.MMMd(_localeOf(strings)).format(createdAt);
  }

  /// Playback position or recording length, as m:ss.
  ///
  /// Deliberately not localised: a timecode is read as a number, and
  /// translating the separator would make it harder to scan, not easier.
  static String duration(Duration? value) {
    if (value == null) return '0:00';
    final minutes = value.inMinutes;
    final seconds = value.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Distance from a viewer position to a job, or null when the viewer's
  /// location is unknown.
  static String? distanceToJob(AppStrings strings, JobLocation? from, Job job) {
    if (from == null) return null;
    return distance(strings, from.distanceTo(job.location));
  }
}
