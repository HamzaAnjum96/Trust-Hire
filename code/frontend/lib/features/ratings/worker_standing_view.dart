import 'package:flutter/material.dart';
import '../../core/roles.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../app/rating_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
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

    // **A fact bar, since 0.24.** Three facts of the same kind, read across:
    // one card, three cells, hairlines between. As three stacked sentences
    // they read as prose, and the number a hirer is comparing sat at the
    // end of a different line each time.
    final rating = standing.averageStars;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading ?? strings.workerStanding,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: BrandSizing.spaceSm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Fact(
                  label: strings.factRating,
                  // New is not bad: no stars, and the words say why.
                  value: rating == null
                      ? strings.notRatedYet
                      : rating.toStringAsFixed(1),
                  isNumber: rating != null,
                  leading: Icon(
                    rating == null
                        ? Icons.star_border_rounded
                        : Icons.star_rounded,
                    size: 20,
                    color: rating == null
                        ? context.colours.textMuted
                        : context.colours.rating,
                  ),
                ),
              ),
              const VerticalDivider(width: BrandSizing.spaceMd),
              Expanded(
                child: _Fact(
                  label: strings.factJobsFinished,
                  value: '${standing.completedJobs}',
                  spoken: strings.jobsCompleted(standing.completedJobs),
                  isNumber: true,
                ),
              ),
              // Aggregated, never per job: Section 10's reason this is shown
              // at all. With no finished job there is nothing to average,
              // and a cell saying so would be a third "not yet".
              if (standing.averageFare != null) ...[
                const VerticalDivider(width: BrandSizing.spaceMd),
                Expanded(
                  child: _Fact(
                    label: strings.factUsualFare,
                    value: Format.fare(strings, standing.averageFare!),
                    spoken: strings.averageFare(
                      Format.fare(strings, standing.averageFare!),
                    ),
                    isNumber: true,
                  ),
                ),
              ],
            ],
          ),
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

/// One cell of the fact bar: the value large, its label small beneath.
///
/// A number shrinks to fit rather than wrap: "Rs. 12,500" broken over two
/// lines is two numbers. Words ("Not rated yet") wrap instead. Read aloud as
/// one sentence, so a screen reader does not say "12, Jobs finished".
class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    required this.isNumber,
    this.spoken,
    this.leading,
  });

  final String label;
  final String value;
  final bool isNumber;
  final String? spoken;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueText = Text(
      value,
      style: isNumber ? theme.fareStyle : theme.textTheme.bodyMedium,
      maxLines: isNumber ? 1 : 3,
    );

    return Semantics(
      label: spoken ?? '$label, $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: BrandSizing.spaceXs),
              ],
              Flexible(
                child: isNumber
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: valueText,
                      )
                    : valueText,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.colours.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
