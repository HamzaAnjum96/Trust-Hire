import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';

/// One job in a list.
///
/// Shared by the browse list and the saved/posted lists so a job looks the
/// same wherever it appears — three lists drifting apart was a real risk once
/// Sprint 11 added two of them.
class JobRow extends StatelessWidget {
  const JobRow({
    super.key,
    required this.job,
    required this.now,
    required this.onTap,
  });

  final Job job;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BrandSizing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.displayTitle(strings),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (job.isLocal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BrandSizing.spaceSm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColours.copper,
                        borderRadius: BrandRadius.smallAll,
                      ),
                      child: Text(
                        strings.onThisDevice,
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: BrandColours.white,
                        ),
                      ),
                    ),
                ],
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
              const SizedBox(height: BrandSizing.spaceSm + 4),
              Wrap(
                spacing: BrandSizing.spaceMd,
                runSpacing: BrandSizing.spaceXs,
                children: [
                  // One tag only, and never the one the heading already
                  // said. A row is for scanning; the sheet lists all three
                  // for the worker actually deciding whether to bid.
                  if (job.supportingTags.isNotEmpty)
                    _Meta(
                      icon: job.supportingTags.first.icon,
                      label: job.supportingTags.first.label(strings),
                    ),
                  _Meta(
                    icon: Icons.schedule,
                    label: Format.scheduled(strings, job.scheduledTime, now),
                  ),
                  if (job.hasVoiceNote)
                    _Meta(icon: Icons.mic, label: strings.voiceNote),
                  if (job.hasPhotos)
                    _Meta(
                      icon: Icons.photo_library_outlined,
                      label: strings.photoCount(job.photoPaths.length),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: BrandSizing.spaceXs + 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
