import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'account.dart';
import 'job_status.dart';
import 'job_tag.dart';

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
    this.tags = const <JobTag>{},
    this.radiusMetres = 1000,
    this.geofenceMetres,
    this.openToAllLocations = false,
    this.startingFare,
    this.agreedFare,
    this.acceptedWorkerId,
    this.status = JobStatus.open,
    this.area,
    this.scheduledTime,
    this.voiceNotePath,
    this.voiceNoteDuration,
    this.photoPaths = const <String>[],
    this.shortDescription,
    this.contactNumber,
    this.postedBy,
    this.isLocal = false,
    this.bookedWorkerId,
    this.listedFare,
  });

  final String id;
  final JobLocation location;
  final DateTime createdAt;

  /// Optional — a job can be described by voice or photo instead.
  final String? title;

  /// What kind of work this is — 1 to 3 tags, chosen by the hirer. This is
  /// what decides who sees the job (section 8), so it is required on anything
  /// posted from now on.
  ///
  /// The model still tolerates an empty set, because jobs written by the POC
  /// are already in local storage and refusing to load them would lose a
  /// user's work. [primaryTag] gives those a sensible icon.
  final Set<JobTag> tags;

  /// The tag a job leads with, for the marker and the heading.
  JobTag? get primaryTag => tags.isEmpty ? null : tags.first;

  /// Distance beyond which this job is not shown, or null for the default.
  final double? geofenceMetres;

  /// Set by the hirer for work that needs no physical presence (section 6).
  final bool openToAllLocations;

  /// What the hirer opened at, in rupees.
  ///
  /// Section 4 is explicit that this is a starting point and not a price —
  /// workers counter it. Optional, because a hirer who has no idea what the
  /// work is worth should not be blocked from asking.
  final int? startingFare;

  /// The fare agreed when the hirer accepted a bid. Null until then.
  ///
  /// **Locked once set.** Section 4 forbids renegotiation after acceptance,
  /// and Section 11 leans on that: the commission is trustworthy precisely
  /// because the number it is taken from was fixed before the work started.
  /// Nothing writes this twice — see [withAcceptedBid].
  final int? agreedFare;

  /// Who the hirer chose. Null until a bid is accepted.
  final String? acceptedWorkerId;

  /// Where the job is in its life (Section 7).
  final JobStatus status;

  /// True once the hirer has chosen someone. No further bids are taken.
  bool get isAccepted => acceptedWorkerId != null;

  /// Whether this job counts toward [workerId]'s history.
  ///
  /// Both halves matter: a job they were chosen for but that was cancelled is
  /// not work they did, and a completed job somebody else did is not theirs.
  bool isCompletedBy(String workerId) =>
      status == JobStatus.completed && acceptedWorkerId == workerId;

  /// The booked worker says yes.
  ///
  /// Section 9: a Mode B booking is not negotiated, so the fare was fixed when
  /// the hirer booked it and acceptance only records who is doing it. Returns
  /// the job unchanged when there is nobody to accept — the same shape as
  /// [withAcceptedBid], because a stale button is a race rather than an error.
  Job withBookingAccepted() {
    final worker = bookedWorkerId;
    if (worker == null || isAccepted) return this;

    return _rebuild(acceptedWorkerId: worker, status: JobStatus.accepted);
  }

  /// This job at a new point in its life.
  ///
  /// Separate from [copyWith] on purpose: editing a job and moving it forward
  /// are different acts, and the edit form must not be able to do the second
  /// by accident.
  Job withStatus(JobStatus next) => _rebuild(status: next);

  /// Where this is, in words — "Gulshan-e-Iqbal, Karachi".
  ///
  /// Added when the seed went national. A list row saying only "Help needed
  /// for a day" is useless once the jobs are eight hundred kilometres apart,
  /// and a worker without location sharing has nothing else to go on. It is a
  /// neighbourhood and a city, never an address, which is the same promise
  /// [radiusMetres] makes on the map.
  final String? area;

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

  /// Id of the account that posted it, if known. Seeded jobs carry a seed user
  /// id; jobs posted in the app carry whichever demo account was active.
  final String? postedBy;

  /// True for jobs created in the app rather than loaded from the seed.
  ///
  /// This is about where the job came from, not about who owns it — the two
  /// were the same thing until demo accounts arrived. Ownership is
  /// [isPostedBy].
  final bool isLocal;

  /// Whether [accountId] is the hirer here.
  ///
  /// This decides who may edit the job, who sees the offers on it, who cannot
  /// bid on it, and which marker gets the copper treatment from section 15 of
  /// the brand guidelines.
  ///
  /// The fallback covers jobs written before the switcher existed: they were
  /// created on this device by the one identity there was, so they belong to
  /// [DemoAccounts.deviceId]. Without it, an update would orphan everything a
  /// user had already posted.
  bool isPostedBy(String accountId) =>
      (postedBy ?? (isLocal ? DemoAccounts.deviceId : null)) == accountId;

  /// The worker this job was booked from, for a Mode B booking.
  ///
  /// Section 9: a directory booking "creates a job record flagged as a direct
  /// request to that one worker (not broadcast)". So this is not a preference
  /// — it is the difference between a job that goes to everybody and a job
  /// that goes to one person, and [JobVisibility] treats it that way.
  final String? bookedWorkerId;

  /// The price the worker listed the service at, before the hirer's discount.
  ///
  /// Kept alongside [agreedFare] rather than derived from it, because the
  /// commission is charged on this number and recovering it by dividing back
  /// through a rounded percentage would drift by a rupee or two — on the one
  /// figure a worker is entitled to check.
  final int? listedFare;

  /// Whether this job came from the directory rather than from the map.
  bool get isDirectBooking => bookedWorkerId != null;

  /// What the hirer saved by booking in the app, or null in Mode A.
  int? get hirerSaving => (listedFare == null || agreedFare == null)
      ? null
      : listedFare! - agreedFare!;

  /// Whether the job carries anything a person can actually understand it by.
  /// Used to keep posting flexible without allowing entirely empty jobs.
  bool get hasContent =>
      // A tag is content in its own right: it says what the work is.
      tags.isNotEmpty ||
      (title != null && title!.trim().isNotEmpty) ||
      (shortDescription != null && shortDescription!.trim().isNotEmpty) ||
      voiceNotePath != null ||
      photoPaths.isNotEmpty;

  bool get hasContact =>
      contactNumber != null && contactNumber!.trim().isNotEmpty;

  bool get hasVoiceNote => voiceNotePath != null;
  bool get hasPhotos => photoPaths.isNotEmpty;

  /// Whether anyone can *read* what this job is about.
  bool get hasTextDescription =>
      (title != null && title!.trim().isNotEmpty) ||
      (shortDescription != null && shortDescription!.trim().isNotEmpty);

  /// A job whose only description is a recording.
  ///
  /// WCAG 1.2.1 asks for a text alternative to prerecorded audio, and there
  /// isn't one: the poster spoke instead of writing, which is the whole point
  /// of the product. Requiring text would shut out exactly the people it
  /// exists for. What the app can do is be honest about it — say the
  /// description is audio, rather than showing a player and leaving someone
  /// who cannot hear it to work out that they have missed something.
  ///
  /// The tags, the area and the time are still readable, so a job is never
  /// entirely opaque. Transcripts need a backend and arrive with it in P1-8.
  bool get isAudioOnly => hasVoiceNote && !hasTextDescription;

  /// The tag [displayTitle] falls back to, or null when it uses something
  /// else. Kept in one place so the heading and [supportingTags] cannot
  /// disagree about which tag has already been said.
  JobTag? get _headingTag {
    if (title != null && title!.trim().isNotEmpty) return null;
    if (shortDescription != null && shortDescription!.trim().isNotEmpty) {
      return null;
    }

    // A chosen tag beats "Voice note job" as a heading — it says what the
    // work is rather than how it was described. "General work" says nothing,
    // so it does not qualify.
    final chosen = primaryTag;
    return (chosen == null || chosen == JobTag.misc) ? null : chosen;
  }

  /// A title to show when the poster did not type one. Falls back through the
  /// description, then the leading tag, then the media the job does have —
  /// never an empty heading.
  String displayTitle(AppStrings strings) {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;

    final d = shortDescription?.trim();
    if (d != null && d.isNotEmpty) {
      return d.length <= 40 ? d : '${d.substring(0, 39)}…';
    }

    final heading = _headingTag;
    if (heading != null) return heading.label(strings);

    if (hasVoiceNote) return strings.voiceNoteJob;
    if (hasPhotos) return strings.photoJob;
    return strings.untitledJob;
  }

  /// The tags worth showing *underneath* [displayTitle].
  ///
  /// Excludes the tag the heading was derived from, for the same reason
  /// [supportingDescription] exists: a job with no typed title should not
  /// print "Cleaning" as its heading and "Cleaning" again as its kind of work.
  Set<JobTag> get supportingTags {
    final heading = _headingTag;
    if (heading == null) return tags;
    return tags.where((tag) => tag != heading).toSet();
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
    final chosen = primaryTag;
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

  /// This job with a worker chosen and the fare locked.
  ///
  /// The only place [agreedFare] is ever set, and it refuses to run twice — a
  /// second acceptance would silently rewrite the number the commission is
  /// calculated from, which is what Section 4 forbids.
  Job withAcceptedBid({required String workerId, required int fare}) {
    if (isAccepted) return this;

    return _rebuild(
      agreedFare: fare,
      acceptedWorkerId: workerId,
      status: JobStatus.accepted,
    );
  }

  /// Every field carried across, with a few replaced. Private, so the only
  /// ways to change a job from outside are [copyWith] for an edit and the
  /// named transitions for everything else.
  Job _rebuild({int? agreedFare, String? acceptedWorkerId, JobStatus? status}) {
    return Job(
      id: id,
      location: location,
      createdAt: createdAt,
      title: title,
      tags: tags,
      geofenceMetres: geofenceMetres,
      openToAllLocations: openToAllLocations,
      startingFare: startingFare,
      agreedFare: agreedFare ?? this.agreedFare,
      acceptedWorkerId: acceptedWorkerId ?? this.acceptedWorkerId,
      status: status ?? this.status,
      area: area,
      radiusMetres: radiusMetres,
      scheduledTime: scheduledTime,
      voiceNotePath: voiceNotePath,
      voiceNoteDuration: voiceNoteDuration,
      photoPaths: photoPaths,
      shortDescription: shortDescription,
      contactNumber: contactNumber,
      postedBy: postedBy,
      isLocal: isLocal,
      bookedWorkerId: bookedWorkerId,
      listedFare: listedFare,
    );
  }

  Job copyWith({
    String? title,
    bool clearTitle = false,
    Set<JobTag>? tags,
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
    int? startingFare,
    bool clearStartingFare = false,
  }) {
    return Job(
      id: id,
      location: location ?? this.location,
      createdAt: createdAt,
      title: clearTitle ? null : (title ?? this.title),
      tags: tags ?? this.tags,
      geofenceMetres: geofenceMetres,
      openToAllLocations: openToAllLocations,
      startingFare: clearStartingFare
          ? null
          : (startingFare ?? this.startingFare),
      // Deliberately not editable: editing a job must never touch the agreed
      // fare or who was chosen.
      agreedFare: agreedFare,
      acceptedWorkerId: acceptedWorkerId,
      status: status,
      area: area,
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
      bookedWorkerId: bookedWorkerId,
      listedFare: listedFare,
    );
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    final durationMs = json['voiceNoteDurationMs'] as int?;
    return Job(
      id: json['id'] as String,
      location: JobLocation.fromJson(json['location'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: json['title'] as String?,
      // Jobs written before tags existed carry a single `type`; read it so a
      // user's existing work is not lost on upgrade.
      tags:
          ((json['tags'] as List<dynamic>?) ??
                  [if (json['type'] != null) json['type']])
              .map((id) => JobTag.fromId(id as String?))
              .whereType<JobTag>()
              .toSet(),
      geofenceMetres: (json['geofenceMetres'] as num?)?.toDouble(),
      openToAllLocations: json['openToAllLocations'] as bool? ?? false,
      startingFare: (json['startingFare'] as num?)?.round(),
      agreedFare: (json['agreedFare'] as num?)?.round(),
      acceptedWorkerId: json['acceptedWorkerId'] as String?,
      // Jobs written before P1-3 have no status. One with a worker on it was
      // accepted; everything else was open.
      status: json['status'] == null
          ? (json['acceptedWorkerId'] == null
                ? JobStatus.open
                : JobStatus.accepted)
          : JobStatus.fromId(json['status'] as String),
      area: json['area'] as String?,
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
    'tags': tags.map((t) => t.id).toList(),
    'geofenceMetres': geofenceMetres,
    'openToAllLocations': openToAllLocations,
    'startingFare': startingFare,
    'agreedFare': agreedFare,
    'acceptedWorkerId': acceptedWorkerId,
    'status': status.id,
    'area': area,
    'radiusMetres': radiusMetres,
    'scheduledTime': scheduledTime?.toIso8601String(),
    'voiceNotePath': voiceNotePath,
    'voiceNoteDurationMs': voiceNoteDuration?.inMilliseconds,
    'photoPaths': photoPaths,
    'shortDescription': shortDescription,
    'contactNumber': contactNumber,
    'postedBy': postedBy,
    'isLocal': isLocal,
    'bookedWorkerId': bookedWorkerId,
    'listedFare': listedFare,
  };
}
