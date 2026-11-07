import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/account_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../widgets/fare_tag.dart';
import '../../widgets/meta_chip.dart';
import '../../widgets/mine_badge.dart';

/// One job in a list.
///
/// Shared by the browse list and the saved/posted lists so a job looks the
/// same wherever it appears — three lists drifting apart was a real risk once
/// Sprint 11 added two of them.
///
/// **The fare leads.** It is the first thing a worker scans a list for, and
/// until 0.20 a row did not show it at all — it was two taps away, in the
/// sheet. So it sits opposite the title, bold, with what kind of number it is
/// underneath: a starting point, or what was agreed.
class JobRow extends StatelessWidget {
  const JobRow({
    super.key,
    required this.job,
    required this.now,
    required this.onTap,
    this.viewerLocation,
    this.isSelected = false,
    this.onOpen,
    this.marksOwnPosting = true,
  });

  final Job job;
  final DateTime now;
  final VoidCallback onTap;

  /// Where the person looking is, when the app knows — for "2.1 km away".
  final JobLocation? viewerLocation;

  /// Marks the row whose pin is selected on the map beside it. Only ever true
  /// in the wide-screen rail, where the two halves have to agree about which
  /// job is being looked at.
  final bool isSelected;

  /// When set, the row separates *look at this on the map* from *open it*.
  ///
  /// The rail needs both: opening a sheet on every click would make the list
  /// unbrowsable, and having no way through to the details would make it
  /// useless. A list with nowhere else to go leaves this null and opens on tap.
  final VoidCallback? onOpen;

  /// Whether a job the viewer posted says so. Off in the Posted tab, where
  /// every row is the viewer's and the badge would be the same word on every
  /// card.
  final bool marksOwnPosting;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final distance = Format.distanceToJob(strings, viewerLocation, job);
    final mine =
        marksOwnPosting &&
        job.isPostedBy(context.watch<AccountController>().activeId);

    // **A row, not a card.** Until 0.23 every job was a bordered, rounded
    // box with a gap under it, and so was everything else in the app — offers,
    // notices, settings, the map preview — which left nothing to tell a list
    // from the things that sit on top of it. A list of jobs is a list: rows on
    // the page, a hairline between them (the list draws it), the fare across
    // from the title.
    //
    // Selection is a sand fill and a burgundy title. It used to be a border,
    // when there was a border to change.
    final selectedFill = theme.brightness == Brightness.light
        ? BrandColours.warmSand
        : BrandColours.darkElevated;

    return Semantics(
      selected: isSelected,
      child: Material(
        color: isSelected ? selectedFill : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BrandSizing.spaceMd,
              BrandSizing.spaceMd - 2,
              BrandSizing.spaceMd,
              BrandSizing.spaceMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.displayTitle(strings),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isSelected ? theme.accentText : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (mine) ...[
                              const SizedBox(height: BrandSizing.spaceXs),
                              const MineBadge(),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: BrandSizing.spaceMd),
                      // Never more than about two fifths of the row: a large
                      // fare at the largest text size must not squeeze the
                      // title down to a word a line.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.42,
                        ),
                        child: FareTag(job: job),
                      ),
                    ],
                  ),
                ),
                if (job.supportingDescription != null) ...[
                  const SizedBox(height: BrandSizing.spaceXs),
                  Text(
                    job.supportingDescription!,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: BrandSizing.spaceSm),
                Wrap(
                  spacing: BrandSizing.spaceMd,
                  runSpacing: BrandSizing.spaceXs,
                  children: [
                    // Where, before when. Once the jobs span a country, a row
                    // that says only what and when is a row a worker cannot
                    // use.
                    if (job.area != null)
                      MetaChip(icon: Icons.place_outlined, label: job.area!),
                    if (distance != null)
                      MetaChip(icon: Icons.near_me_outlined, label: distance),
                    MetaChip(
                      icon: Icons.schedule,
                      label: Format.scheduled(strings, job.scheduledTime, now),
                    ),
                    // One tag only, and never the one the heading already
                    // said. A row is for scanning; the sheet lists all three
                    // for the worker actually deciding whether to bid.
                    if (job.supportingTags.isNotEmpty)
                      MetaChip(
                        icon: job.supportingTags.first.icon,
                        label: job.supportingTags.first.label(strings),
                      ),
                    if (job.hasVoiceNote)
                      MetaChip(
                        icon: Icons.mic,
                        iconColor: theme.colorScheme.secondary,
                        // Distinguishes "has a voice note as well" from "the
                        // voice note is all there is", which decides whether
                        // this row is worth opening at all.
                        label: job.isAudioOnly
                            ? strings.audioOnlyJob
                            : strings.voiceNote,
                      ),
                    if (job.hasPhotos)
                      MetaChip(
                        icon: Icons.photo_library_outlined,
                        label: strings.photoCount(job.photoPaths.length),
                      ),
                  ],
                ),

                // Only on the row that is selected. On every row of the rail
                // it was the same button forty times, louder than the jobs.
                if (onOpen != null && isSelected) ...[
                  const SizedBox(height: BrandSizing.spaceSm),
                  FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_full, size: 18),
                    label: Text(strings.openDetails),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
