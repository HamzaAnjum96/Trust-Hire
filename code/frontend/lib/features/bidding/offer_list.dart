import 'package:flutter/material.dart';
import '../../core/roles.dart';
import 'package:provider/provider.dart';

import '../../app/bid_controller.dart';
import '../../app/job_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bid.dart';
import '../../models/job.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_pill.dart';
import '../ratings/worker_standing_view.dart';

/// What the hirer sees on their own job: every offer, and the choice.
///
/// Section 4 requires the hirer to choose manually — no auto-selection, not
/// lowest-bid-wins and not first-come-first-served. Cheapest is listed first
/// because a list needs an order, but nothing here marks a row as the one to
/// take, and the top row gets no more emphasis than any other.
///
/// **A radio group and one button, since 0.24.** Choosing an offer sets one
/// value, so the offers are a radio group: tap a row to select it, then one
/// button — "Choose Rs. 2,500" — asks to confirm. It used to be a filled
/// "Choose" on every offer, four or five accent buttons on one screen, and
/// the button you pressed named nothing about what you were agreeing to.
class OfferList extends StatefulWidget {
  const OfferList({super.key, required this.job});

  final Job job;

  @override
  State<OfferList> createState() => _OfferListState();
}

class _OfferListState extends State<OfferList> {
  String? _selectedId;

  Future<void> _choose(Bid bid) async {
    final strings = AppStrings.of(context);
    final bids = context.read<BidController>();
    final jobs = context.read<JobController>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
    final updated = await bids.accept(bid, job: widget.job);
    await jobs.saveJob(updated);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final job = widget.job;
    final bids = context.watch<BidController>().forReview(job.id);
    final open = !job.isAccepted;

    Bid? selected;
    for (final bid in bids) {
      if (bid.id == _selectedId) selected = bid;
    }

    final rows = Column(
      children: [
        for (final (i, bid) in bids.indexed) ...[
          if (i > 0) const Divider(),
          _OfferRow(
            bid: bid,
            selectable: open,
            selected: open && bid.id == _selectedId,
            onSelect: () => setState(() => _selectedId = bid.id),
          ),
        ],
      ],
    );

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
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: BrandSizing.spaceSm),

        if (bids.isEmpty)
          Text(strings.noOffersYet, style: theme.textTheme.bodyMedium)
        else ...[
          if (open) ...[
            NoticePanel(
              message: strings.fareLocked,
              icon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: BrandSizing.spaceSm),
          ],
          // One framed group: the offers are compared with each other, so
          // they sit together rather than as separate cards.
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colours.surface,
              borderRadius: BrandRadius.largeAll,
              boxShadow: context.colours.card,
            ),
            child: ClipRRect(
              borderRadius: BrandRadius.largeAll,
              child: open
                  ? RadioGroup<String>(
                      groupValue: _selectedId,
                      onChanged: (id) => setState(() => _selectedId = id),
                      child: rows,
                    )
                  : rows,
            ),
          ),
          if (open) ...[
            const SizedBox(height: BrandSizing.spaceMd),
            FilledButton(
              onPressed: selected == null ? null : () => _choose(selected!),
              child: Text(
                selected == null
                    ? strings.chooseAnOffer
                    : strings.chooseOffer(Format.fare(strings, selected.fare)),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// One offer: its fare in a fixed column, who is asking, and what they said.
class _OfferRow extends StatelessWidget {
  const _OfferRow({
    required this.bid,
    required this.selectable,
    required this.selected,
    required this.onSelect,
  });

  final Bid bid;
  final bool selectable;

  /// The offer the hirer has picked, before confirming. It takes the same
  /// turmeric wash as a selected row in the job list, so selection reads one
  /// way across the app.
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    final isChosen = bid.status == BidStatus.accepted;
    final isPassedOver = bid.status == BidStatus.passedOver;

    final content = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        selectable ? BrandSizing.spaceXs : BrandSizing.spaceMd,
        BrandSizing.spaceSm + 4,
        BrandSizing.spaceMd,
        BrandSizing.spaceSm + 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectable) Radio<String>(value: bid.id),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Format.fare(strings, bid.fare),
                        style: theme.fareStyle.copyWith(
                          // A passed-over offer stays legible — greying it
                          // out would make the hirer's own history hard to
                          // read back.
                          color: isPassedOver
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                    if (isChosen)
                      StatusPill.emphasised(context, strings.chosen)
                    else if (isPassedOver)
                      StatusPill.muted(context, strings.notChosen),
                  ],
                ),
                // Section 10's whole purpose, in the one place it can change
                // an outcome: what a worker has done before, next to what
                // they are asking for it.
                const SizedBox(height: BrandSizing.spaceXs),
                WorkerStandingView(workerId: bid.workerId, compact: true),
                if (bid.message != null) ...[
                  const SizedBox(height: BrandSizing.spaceXs),
                  Text(bid.message!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!selectable) return content;
    // The radio takes keyboard focus; the row is the bigger target for a
    // finger. One stop per offer, not two.
    return Material(
      color: selected ? context.colours.selection : Colors.transparent,
      child: InkWell(onTap: onSelect, canRequestFocus: false, child: content),
    );
  }
}
