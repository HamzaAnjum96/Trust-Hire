import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../core/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/job.dart';

/// A job's fare, and what kind of number it is.
///
/// An agreed fare is the one locked at acceptance, so it says so and carries
/// the lock; a starting fare is the hirer's opening, and says that. A job with
/// neither says it is open to offers, so a row without a number does not read
/// as a row with a missing one.
///
/// One widget for the job row, the map's preview card and the job sheet, so
/// the fare — the first thing a worker looks for — reads the same everywhere.
class FareTag extends StatelessWidget {
  const FareTag({super.key, required this.job, this.large = false});

  final Job job;

  /// The job sheet's size: the fare is the headline there, not a detail.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final agreed = job.agreedFare;
    final fare = agreed ?? job.startingFare;
    final align = large ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    if (fare == null) {
      return Text(
        strings.fareOpenToOffers,
        style: large
            ? theme.textTheme.titleMedium
            : theme.textTheme.labelMedium,
        textAlign: large ? TextAlign.start : TextAlign.end,
        maxLines: 2,
      );
    }

    final amount = theme.fareStyle.copyWith(
      fontSize: large ? 28 : null,
      height: large ? 34 / 28 : null,
    );

    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shrunk rather than cut: "Rs. 10,0…" would be a different fare.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: large
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: Text(Format.fare(strings, fare), style: amount),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (agreed != null) ...[
              Icon(
                Icons.lock_outline,
                size: large ? 14 : 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: BrandSizing.spaceXs - 2),
            ],
            Flexible(
              child: Text(
                agreed != null
                    ? strings.fareAgreedLabel
                    : strings.fieldStartingFare,
                style: large
                    ? theme.textTheme.labelMedium
                    : theme.textTheme.labelSmall,
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
