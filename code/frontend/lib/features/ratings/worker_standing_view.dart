import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../app/rating_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/rating.dart';

/// A worker's public record: a rating, a count, and what they usually charge.
///
/// Three numbers, and Section 10 is specific about why the third is one of
/// them. The fare average is **aggregated** and never broken down per job,
/// which is what makes under-declaring a fare to dodge commission
/// self-defeating: the worker lowers the very figure future hirers anchor on.
///
/// An unrated worker shows no stars rather than a zero. New is not bad, and a
/// zero out of five says the opposite of the truth about somebody who has
/// simply not started yet.
class WorkerStandingView extends StatelessWidget {
  const WorkerStandingView({
    super.key,
    required this.workerId,
    this.compact = false,
    this.heading,
  });

  final String workerId;

  /// Overrides the heading. The default reads from a hirer's point of view —
  /// "their record" — which is wrong on the one screen where the worker is
  /// looking at themselves.
  final String? heading;

  /// A single line, for a row that already has a fare and a name on it.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    final jobs = context.watch<JobController>().jobs;
    final standing = context.watch<RatingController>().standingFor(
      workerId,
      jobs: jobs,
    );

    if (compact) {
      // A drawn star, not the ★ character: a glyph from whatever font has
      // one is a different shape and weight on every device, beside icons
      // that are all one family. At the meta row's size, so it reads as one
      // more fact on the row.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (standing.hasHistory && standing.hasRating) ...[
            Icon(
              Icons.star_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: BrandSizing.spaceXs),
          ],
          Flexible(
            child: Text(
              _summary(standing, strings),
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading ?? strings.workerStanding,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: BrandSizing.spaceXs),
        Row(
          children: [
            Icon(
              standing.hasRating ? Icons.star : Icons.star_border,
              size: 20,
              color: standing.hasRating
                  ? BrandColours.copper
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: BrandSizing.spaceXs),
            // Flexible, because this is a number in English and a phrase in
            // Urdu. "Not rated yet" is three short words; its translation is
            // long enough to run off a 390px phone, which it did.
            Flexible(
              child: Text(
                standing.hasRating
                    ? standing.averageStars!.toStringAsFixed(1)
                    : strings.notRatedYet,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: BrandSizing.spaceXs),
        Text(
          strings.jobsCompleted(standing.completedJobs),
          style: theme.textTheme.bodyMedium,
        ),
        if (standing.averageFare != null)
          Text(
            strings.averageFare(Format.fare(strings, standing.averageFare!)),
            style: theme.textTheme.bodyMedium,
          ),
      ],
    );
  }

  /// The same three facts on one line, for an offer row.
  String _summary(WorkerStanding standing, AppStrings strings) {
    if (!standing.hasHistory) return strings.newToTrustHire;

    return [
      if (standing.hasRating)
        standing.averageStars!.toStringAsFixed(1)
      else
        strings.notRatedYet,
      strings.jobsCompleted(standing.completedJobs),
    ].join(' · ');
  }
}
