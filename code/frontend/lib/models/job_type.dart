import 'package:flutter/material.dart';

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
  plumbing('Plumbing', Icons.plumbing),
  electrical('Electrical', Icons.electrical_services),
  painting('Painting', Icons.format_paint),
  carpentry('Carpentry', Icons.carpenter),
  masonry('Masonry', Icons.foundation),
  construction('Construction', Icons.construction),
  applianceRepair('Appliance repair', Icons.ac_unit),
  cleaning('Cleaning', Icons.cleaning_services),
  moving('Moving', Icons.local_shipping),
  driving('Driving', Icons.directions_car),
  gardening('Gardening', Icons.yard),
  tailoring('Tailoring', Icons.checkroom),
  cooking('Cooking', Icons.restaurant),
  tutoring('Tutoring', Icons.school),
  security('Security', Icons.shield_outlined),
  other('Something else', Icons.handyman);

  const JobType(this.label, this.icon);

  /// Shown to the user. Plain words, per section 20 — "Plumbing", never
  /// "Sanitary Installation Services".
  final String label;

  final IconData icon;

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
