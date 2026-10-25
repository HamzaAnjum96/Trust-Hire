import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/account_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final distance = Format.distanceToJob(strings, viewerLocation, job);
    final mine = job.isPostedBy(context.watch<AccountController>().activeId);

    return Card(
      clipBehavior: Clip.antiAlias,
      // Selection is a border rather than a fill: these rows already carry a
      // copper badge and coloured meta, and a tinted background behind them
      // costs the text its contrast.
      shape: RoundedRectangleBorder(
        borderRadius: BrandRadius.largeAll,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BrandSizing.spaceMd),
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
                            style: theme.textTheme.titleLarge,
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
                      child: _Fare(job: job),
                    ),
                  ],
                ),
              ),
              if (job.supportingDescription != null) ...[
                const SizedBox(height: BrandSizing.spaceSm),
                Text(
                  job.supportingDescription!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: BrandSizing.spaceSm + 4),
              Wrap(
                spacing: BrandSizing.spaceMd,
                runSpacing: BrandSizing.spaceXs,
                children: [
                  // Where, before when. Once the jobs span a country, a row
                  // that says only what and when is a row a worker cannot use.
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

              if (onOpen != null) ...[
                const SizedBox(height: BrandSizing.spaceSm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_full, size: 16),
                    label: Text(strings.openDetails),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The fare, and what kind of number it is.
///
/// An agreed fare is the one that was locked at acceptance, so it says so and
/// carries the lock; a starting fare is the hirer's opening, and says that. A
/// job with neither says it is open to offers, so a row without a number does
/// not read as a row with a missing one.
class _Fare extends StatelessWidget {
  const _Fare({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final agreed = job.agreedFare;
    final fare = agreed ?? job.startingFare;

    if (fare == null) {
      return Text(
        strings.fareOpenToOffers,
        style: theme.textTheme.labelMedium,
        textAlign: TextAlign.end,
        maxLines: 2,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shrunk rather than cut: "Rs. 10,0…" would be a different fare.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Text(Format.fare(strings, fare), style: theme.fareStyle),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (agreed != null) ...[
              Icon(
                Icons.lock_outline,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 2),
            ],
            Flexible(
              child: Text(
                agreed != null
                    ? strings.fareAgreedLabel
                    : strings.fieldStartingFare,
                style: theme.textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
