import 'package:flutter/material.dart';

import '../../core/tokens.dart';
import '../../models/job_tag.dart';
import '../../widgets/tag_tile.dart';
import 'job_draft_controller.dart';

/// Choosing what kind of work a job is.
///
/// Required since P1-1, because this is what decides who ever sees the job. It
/// is the one thing the form insists on, and the save bar says why rather than
/// marking the field with an asterisk.
///
/// Tiles rather than a dropdown — a dropdown means two taps and a scroll on a
/// small screen, and hides every option until opened.
class JobTagField extends StatelessWidget {
  const JobTagField({super.key, required this.draft});

  final JobDraftController draft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: JobTag.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: BrandSizing.spaceSm),
        itemBuilder: (context, index) {
          final tag = JobTag.values[index];
          return TagTile(
            tag: tag,
            selected: draft.tags.contains(tag),
            // Tapping a chosen tag again removes it, so a mis-tap is not a
            // trap. At three, adding is refused rather than silently evicting
            // an earlier choice.
            enabled: draft.tags.contains(tag) || draft.canAddTag,
            onTap: () => draft.toggleTag(tag),
          );
        },
      ),
    );
  }
}
