import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/bid_controller.dart';
import '../../app/job_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bid.dart';
import '../../models/job.dart';
import '../../widgets/state_views.dart';

/// What the hirer sees on their own job: every offer, and the choice.
///
/// Section 4 requires the hirer to choose manually — no auto-selection, not
/// lowest-bid-wins and not first-come-first-served. Cheapest is listed first
/// because a list needs an order, but nothing here marks a row as the one to
/// take, and the top row gets no more emphasis than any other.
class OfferList extends StatelessWidget {
  const OfferList({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final bids = context.watch<BidController>().forReview(job.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.offersOnThisJob,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              strings.offerCount(bids.length),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: BrandSizing.spaceSm),

        if (bids.isEmpty)
          Text(strings.noOffersYet, style: theme.textTheme.bodyMedium)
        else ...[
          if (!job.isAccepted) ...[
            NoticePanel(message: strings.fareLocked, icon: Icons.lock_outline),
            const SizedBox(height: BrandSizing.spaceSm),
          ],
          for (final bid in bids) ...[
            _OfferRow(job: job, bid: bid),
            const SizedBox(height: BrandSizing.spaceSm),
          ],
        ],
      ],
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.job, required this.bid});

  final Job job;
  final Bid bid;

  Future<void> _choose(BuildContext context) async {
    final strings = AppStrings.of(context);
    final bids = context.read<BidController>();
    final jobs = context.read<JobController>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BrandRadius.largeAll),
        title: Text(strings.confirmChoose(Format.fare(strings, bid.fare))),
        content: Text(strings.fareLocked),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.chooseThisWorker),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // The bid statuses and the job's locked fare are two writes, so the job
    // is saved second: a job claiming an agreed fare with no accepted bid
    // behind it is the worse of the two halves to be left holding.
    final updated = await bids.accept(bid, job: job);
    await jobs.saveJob(updated);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    final isChosen = bid.status == BidStatus.accepted;
    final isPassedOver = bid.status == BidStatus.passedOver;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BrandRadius.mediumAll,
        side: BorderSide(
          color: isChosen
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isChosen ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    Format.fare(strings, bid.fare),
                    style: theme.textTheme.titleLarge?.copyWith(
                      // A passed-over offer stays legible — greying it out
                      // would make the hirer's own history hard to read back.
                      color: isPassedOver
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
                if (isChosen)
                  _StatusChip(label: strings.chosen, emphasised: true)
                else if (isPassedOver)
                  _StatusChip(label: strings.notChosen),
              ],
            ),

            if (bid.message != null) ...[
              const SizedBox(height: BrandSizing.spaceXs),
              Text(bid.message!, style: theme.textTheme.bodyMedium),
            ],

            if (!job.isAccepted) ...[
              const SizedBox(height: BrandSizing.spaceSm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: () => _choose(context),
                  child: Text(strings.chooseThisWorker),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.emphasised = false});

  final String label;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSizing.spaceSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: emphasised
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BrandRadius.smallAll,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: emphasised
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
