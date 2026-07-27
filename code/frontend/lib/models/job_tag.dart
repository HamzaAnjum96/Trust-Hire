import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// The fixed vocabulary that drives who sees what.
///
/// Section 8 of the Phase 1 spec makes this the mechanism that solves the
/// "everyone bids on everything, then cancels" problem, and it only works
/// because the list is closed: free text would give nothing to match on.
///
/// The design is deliberately asymmetric, and that asymmetry is the point:
///
/// - **Hirers tag jobs** — 1 to 3 tags, required.
/// - **Workers never classify anything.** Every worker starts on [misc] with
///   no selection screen, and opts into their own trade if they want to. That
///   asks a worker to recognise their own work, not to file unfamiliar work
///   into an unfamiliar taxonomy — which is what makes it workable for someone
///   who does not read comfortably.
///
/// This replaces the POC's optional job type. The brand guidelines say users
/// should never *choose* a category; the compromise kept here is that the ones
/// being asked are hirers, and the picker is icon-led so choosing does not
/// require reading.
enum JobTag {
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
  legal(Icons.gavel),
  medical(Icons.medical_services_outlined),
  beauty(Icons.content_cut),
  // Every worker holds this by default, and it is a valid job tag too —
  // a hirer who does not know what trade they need can still be seen.
  misc(Icons.handyman);

  const JobTag(this.icon);

  final IconData icon;

  /// Shown to the user, in the active language. Plain words, per section 20 —
  /// "Plumbing", never "Sanitary Installation Services".
  String label(AppStrings strings) => switch (this) {
    JobTag.plumbing => strings.tagPlumbing,
    JobTag.electrical => strings.tagElectrical,
    JobTag.painting => strings.tagPainting,
    JobTag.carpentry => strings.tagCarpentry,
    JobTag.masonry => strings.tagMasonry,
    JobTag.construction => strings.tagConstruction,
    JobTag.applianceRepair => strings.tagApplianceRepair,
    JobTag.cleaning => strings.tagCleaning,
    JobTag.moving => strings.tagMoving,
    JobTag.driving => strings.tagDriving,
    JobTag.gardening => strings.tagGardening,
    JobTag.tailoring => strings.tagTailoring,
    JobTag.cooking => strings.tagCooking,
    JobTag.tutoring => strings.tagTutoring,
    JobTag.security => strings.tagSecurity,
    JobTag.legal => strings.tagLegal,
    JobTag.medical => strings.tagMedical,
    JobTag.beauty => strings.tagBeauty,
    JobTag.misc => strings.tagMisc,
  };

  /// Stored in local storage. Kept separate from [name] so renaming a label
  /// never orphans saved jobs.
  String get id => name;

  /// Every worker starts here, with no selection screen and no decision.
  static const defaultWorkerTags = <JobTag>{JobTag.misc};

  /// The order a **worker** reads their own trades in: general work first.
  ///
  /// It is the one they already hold, it is the one that cannot be switched
  /// off, and the screen shows it selected-and-inert to prove it is on. Having
  /// it eighteenth in the list meant the tile answering "am I still going to
  /// see general jobs?" was the last one anybody found.
  ///
  /// Deliberately not the order a **hirer** picks tags in. There, general work
  /// is the fallback for someone who cannot name the trade they need, and
  /// putting it first would make it the path of least resistance — which would
  /// quietly undo the tag rule the whole of Section 8 rests on.
  static List<JobTag> get workerOrder => [
    ...defaultWorkerTags,
    ...values.where((tag) => !defaultWorkerTags.contains(tag)),
  ];

  static JobTag? fromId(String? id) {
    if (id == null) return null;
    for (final type in JobTag.values) {
      if (type.id == id) return type;
    }
    // An unknown id means data from a newer version; treat it as unset rather
    // than failing to load the job.
    return null;
  }
}
