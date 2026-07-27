import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'job_type.dart';

/// A geographic point. Deliberately approximate — the brand guidelines call
/// for showing a general area rather than an exact address.
class JobLocation {
  const JobLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory JobLocation.fromJson(Map<String, dynamic> json) => JobLocation(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'latitude': latitude,
    'longitude': longitude,
  };

  /// Great-circle distance in metres, via the haversine formula.
  double distanceTo(JobLocation other) {
    const earthRadiusMetres = 6371000.0;
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusMetres * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      other is JobLocation &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// A job posting.
///
/// The core principle from the sprint plan is that **missing information is
/// acceptable**. Only [id], [location] and [createdAt] are required; a job is
/// postable with a voice note alone, a photo alone, or a title alone.
class Job {
  const Job({
    required this.id,
    required this.location,
    required this.createdAt,
    this.title,
    this.type,
    this.radiusMetres = 1000,
    this.scheduledTime,
    this.voiceNotePath,
    this.voiceNoteDuration,
    this.photoPaths = const <String>[],
    this.shortDescription,
    this.contactNumber,
    this.postedBy,
    this.isLocal = false,
  });

  final String id;
  final JobLocation location;
  final DateTime createdAt;

  /// Optional — a job can be described by voice or photo instead.
  final String? title;

  /// The kind of work, when the poster chose one. Optional: an untyped job is
  /// normal, and the marker falls back to showing what the job carries.
  final JobType? type;

  /// The approximate work area, shown as a translucent circle on the map.
  final double radiusMetres;

  /// When the work needs to happen. Null means "no particular time".
  final DateTime? scheduledTime;

  /// Asset path (seeded jobs) or on-device file path (locally created ones).
  final String? voiceNotePath;
  final Duration? voiceNoteDuration;

  final List<String> photoPaths;
  final String? shortDescription;

  /// A phone number people can reach the poster on. Optional like everything
  /// else, and never shown until someone asks to see it.
  final String? contactNumber;

  /// Id of the user who posted it, if known.
  final String? postedBy;

  /// True for jobs created on this device. Drives the copper marker treatment
  /// from section 15 of the brand guidelines.
  final bool isLocal;

  /// Whether the job carries anything a person can actually understand it by.
  /// Used to keep posting flexible without allowing entirely empty jobs.
  bool get hasContent =>
      // A chosen type is content in its own right: it says what the work is.
      type != null ||
      (title != null && title!.trim().isNotEmpty) ||
      (shortDescription != null && shortDescription!.trim().isNotEmpty) ||
      voiceNotePath != null ||
      photoPaths.isNotEmpty;

  bool get hasContact =>
      contactNumber != null && contactNumber!.trim().isNotEmpty;

  bool get hasVoiceNote => voiceNotePath != null;
  bool get hasPhotos => photoPaths.isNotEmpty;

  /// A title to show when the poster did not type one. Falls back through the
  /// description, then the media the job does have — never an empty heading.
  String displayTitle(AppStrings strings) {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;

    final d = shortDescription?.trim();
    if (d != null && d.isNotEmpty) {
      return d.length <= 40 ? d : '${d.substring(0, 39)}…';
    }

    // A chosen type beats "Voice note job" as a heading — it says what the
    // work is rather than how it was described.
    final chosen = type;
    if (chosen != null && chosen != JobType.other) return chosen.label(strings);

    if (hasVoiceNote) return strings.voiceNoteJob;
    if (hasPhotos) return strings.photoJob;
    return strings.untitledJob;
  }

  /// The description to show *underneath* [displayTitle].
  ///
  /// Null when the heading was itself derived from the description, so a job
  /// with no typed title does not print the same sentence twice.
  String? get supportingDescription {
    final t = title?.trim();
    if (t == null || t.isEmpty) return null;

    final d = shortDescription?.trim();
    return (d == null || d.isEmpty) ? null : d;
  }

  /// The glyph that represents this job.
  ///
  /// The chosen type when there is one, otherwise what the job carries — a
  /// microphone for a voice note, a camera for photos. Defined here so the
  /// map, the list and the details sheet cannot disagree about it.
  IconData get icon {
    final chosen = type;
    if (chosen != null) return chosen.icon;
    if (hasVoiceNote) return Icons.mic;
    if (hasPhotos) return Icons.photo_camera;
    return Icons.work;
  }

  /// True when the job is scheduled for today.
  bool isToday(DateTime now) {
    final t = scheduledTime;
    if (t == null) return false;
    return t.year == now.year && t.month == now.month && t.day == now.day;
  }

  Job copyWith({
    String? title,
    bool clearTitle = false,
    JobType? type,
    bool clearType = false,
    JobLocation? location,
    double? radiusMetres,
    DateTime? scheduledTime,
    bool clearScheduledTime = false,
    String? voiceNotePath,
    Duration? voiceNoteDuration,
    bool clearVoiceNote = false,
    List<String>? photoPaths,
    String? shortDescription,
    bool clearShortDescription = false,
    String? contactNumber,
    bool clearContactNumber = false,
  }) {
    return Job(
      id: id,
      location: location ?? this.location,
      createdAt: createdAt,
      title: clearTitle ? null : (title ?? this.title),
      type: clearType ? null : (type ?? this.type),
      radiusMetres: radiusMetres ?? this.radiusMetres,
      scheduledTime: clearScheduledTime
          ? null
          : (scheduledTime ?? this.scheduledTime),
      voiceNotePath: clearVoiceNote
          ? null
          : (voiceNotePath ?? this.voiceNotePath),
      voiceNoteDuration: clearVoiceNote
          ? null
          : (voiceNoteDuration ?? this.voiceNoteDuration),
      photoPaths: photoPaths ?? this.photoPaths,
      shortDescription: clearShortDescription
          ? null
          : (shortDescription ?? this.shortDescription),
      contactNumber: clearContactNumber
          ? null
          : (contactNumber ?? this.contactNumber),
      postedBy: postedBy,
      isLocal: isLocal,
    );
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    final durationMs = json['voiceNoteDurationMs'] as int?;
    return Job(
      id: json['id'] as String,
      location: JobLocation.fromJson(json['location'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: json['title'] as String?,
      type: JobType.fromId(json['type'] as String?),
      radiusMetres: (json['radiusMetres'] as num?)?.toDouble() ?? 1000,
      scheduledTime: json['scheduledTime'] == null
          ? null
          : DateTime.parse(json['scheduledTime'] as String),
      voiceNotePath: json['voiceNotePath'] as String?,
      voiceNoteDuration: durationMs == null
          ? null
          : Duration(milliseconds: durationMs),
      photoPaths:
          (json['photoPaths'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      shortDescription: json['shortDescription'] as String?,
      contactNumber: json['contactNumber'] as String?,
      postedBy: json['postedBy'] as String?,
      isLocal: json['isLocal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'location': location.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'title': title,
    'type': type?.id,
    'radiusMetres': radiusMetres,
    'scheduledTime': scheduledTime?.toIso8601String(),
    'voiceNotePath': voiceNotePath,
    'voiceNoteDurationMs': voiceNoteDuration?.inMilliseconds,
    'photoPaths': photoPaths,
    'shortDescription': shortDescription,
    'contactNumber': contactNumber,
    'postedBy': postedBy,
    'isLocal': isLocal,
  };
}
