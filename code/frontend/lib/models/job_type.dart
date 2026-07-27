import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// The kind of work a job is.
///
/// **Optional by design.** The brand guidelines want categories inferred rather
/// than demanded — section "Smart Categories" says users should never have to
/// choose one, and design principle 2 lists categories under what not to
/// require. So a job with no type is entirely normal: the marker falls back to
/// showing what the job *carries* (a voice note, a photo) instead.
///
/// What choosing a type buys is a clearer map: a plumbing pin and a driving
/// pin read differently at a glance, which a microphone icon on both does not.
enum JobType {
  plumbing(Icons.plumbing),
  electrical(Icons.electrical_services),
  painting(Icons.format_paint),
  carpentry(Icons.carpenter),
  masonry(Icons.foundation),
  construction(Icons.construction),
  applianceRepair(Icons.ac_unit),
  cleaning(Icons.cleaning_services),
  moving(Icons.local_shipping),
  driving(Icons.directions_car),
  gardening(Icons.yard),
  tailoring(Icons.checkroom),
  cooking(Icons.restaurant),
  tutoring(Icons.school),
  security(Icons.shield_outlined),
  other(Icons.handyman);

  const JobType(this.icon);

  final IconData icon;

  /// Shown to the user, in the active language. Plain words, per section 20 —
  /// "Plumbing", never "Sanitary Installation Services".
  String label(AppStrings strings) => switch (this) {
    JobType.plumbing => strings.typePlumbing,
    JobType.electrical => strings.typeElectrical,
    JobType.painting => strings.typePainting,
    JobType.carpentry => strings.typeCarpentry,
    JobType.masonry => strings.typeMasonry,
    JobType.construction => strings.typeConstruction,
    JobType.applianceRepair => strings.typeApplianceRepair,
    JobType.cleaning => strings.typeCleaning,
    JobType.moving => strings.typeMoving,
    JobType.driving => strings.typeDriving,
    JobType.gardening => strings.typeGardening,
    JobType.tailoring => strings.typeTailoring,
    JobType.cooking => strings.typeCooking,
    JobType.tutoring => strings.typeTutoring,
    JobType.security => strings.typeSecurity,
    JobType.other => strings.typeOther,
  };

  /// Stored in local storage. Kept separate from [name] so renaming a label
  /// never orphans saved jobs.
  String get id => name;

  static JobType? fromId(String? id) {
    if (id == null) return null;
    for (final type in JobType.values) {
      if (type.id == id) return type;
    }
    // An unknown id means data from a newer version; treat it as unset rather
    // than failing to load the job.
    return null;
  }
}
