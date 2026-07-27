import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/bid_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import 'bidding_rules.dart';

/// Where a worker names their price.
///
/// One field that matters and one that does not, in that order. A worker who
/// cannot write should be able to bid with a number alone, which is the same
/// rule the posting form follows for jobs.
class OfferSheet extends StatefulWidget {
  const OfferSheet({super.key, required this.job});

  final Job job;

  static Future<void> open(BuildContext context, {required Job job}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => OfferSheet(job: job),
    );
  }

  @override
  State<OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<OfferSheet> {
  late final TextEditingController _fare;
  late final TextEditingController _message;

  BidRefusal? _problem;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final existing = context.read<BidController>().myBidOn(widget.job.id);
    _fare = TextEditingController(
      // Opens on the current offer if there is one, otherwise on the hirer's
      // starting fare — a number to adjust beats an empty box.
      text: '${existing?.fare ?? widget.job.startingFare ?? ''}',
    );
    _message = TextEditingController(text: existing?.message ?? '');
  }

  @override
  void dispose() {
    _fare.dispose();
    _message.dispose();
    super.dispose();
  }

  int? get _enteredFare => int.tryParse(_fare.text.trim());

  Future<void> _send() async {
    final controller = context.read<BidController>();
    final fare = _enteredFare;

    final problem = fare == null
        ? BidRefusal.fareNotPositive
        : controller.rules.refusalForFare(
            fare,
            startingFare: widget.job.startingFare,
          );

    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }

    setState(() {
      _problem = null;
      _isSaving = true;
    });

    await controller.placeBid(
      jobId: widget.job.id,
      fare: fare!,
      message: _message.text,
    );

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _withdraw() async {
    await context.read<BidController>().withdrawBid(widget.job.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final existing = context.watch<BidController>().myBidOn(widget.job.id);

    return Padding(
      padding: EdgeInsets.only(
        left: BrandSizing.spaceMd,
        right: BrandSizing.spaceMd,
        top: BrandSizing.spaceMd,
        // Clear the keyboard, which covers the send button otherwise.
        bottom: MediaQuery.viewInsetsOf(context).bottom + BrandSizing.spaceLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.offerAFare, style: theme.textTheme.headlineMedium),

          if (widget.job.startingFare != null) ...[
            const SizedBox(height: BrandSizing.spaceXs),
            Text(
              strings.startsAt(Format.fare(strings, widget.job.startingFare!)),
              style: theme.textTheme.labelSmall,
            ),
          ],

          const SizedBox(height: BrandSizing.spaceLg),
          TextField(
            controller: _fare,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.headlineMedium,
            decoration: InputDecoration(
              hintText: strings.fareHint,
              prefixText: '${strings.rupees('').trim()} ',
              errorText: switch (_problem) {
                BidRefusal.fareNotPositive => strings.fareMustBePositive,
                BidRefusal.fareImplausible => strings.fareLooksTooHigh,
                _ => null,
              },
            ),
            onChanged: (_) {
              if (_problem != null) setState(() => _problem = null);
            },
          ),

          const SizedBox(height: BrandSizing.spaceMd),
          TextField(
            controller: _message,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: strings.offerMessageHint),
          ),

          const SizedBox(height: BrandSizing.spaceLg),
          ElevatedButton(
            onPressed: _isSaving ? null : _send,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(strings.sendOffer),
          ),

          if (existing != null && existing.status.isOpen) ...[
            const SizedBox(height: BrandSizing.spaceSm),
            TextButton(
              onPressed: _isSaving ? null : _withdraw,
              style: TextButton.styleFrom(
                foregroundColor: BrandColours.errorRed,
              ),
              child: Text(strings.withdrawOffer),
            ),
          ],
        ],
      ),
    );
  }
}

/// The row a worker sees on a job they can bid on.
class OfferAction extends StatelessWidget {
  const OfferAction({super.key, required this.job, required this.refusal});

  final Job job;
  final BidRefusal? refusal;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final mine = context.watch<BidController>().myBidOn(job.id);

    if (refusal != null) {
      // Says why rather than showing a dead button. "Not visible" is not
      // explained: a job the worker cannot see cannot be on their screen to
      // ask about, so reaching it means they opened a saved job that has
      // since moved out of reach.
      final reason = switch (refusal!) {
        BidRefusal.ownJob => strings.cannotBidOwnJob,
        BidRefusal.alreadyAccepted => strings.cannotBidAccepted,
        BidRefusal.walletLocked => strings.walletLocked,
        _ => null,
      };

      if (reason == null) return const SizedBox.shrink();
      return Text(reason, style: theme.textTheme.labelSmall);
    }

    final hasOpenBid = mine != null && mine.status.isOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasOpenBid) ...[
          Text(
            strings.yourOffer(Format.fare(strings, mine.fare)),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: BrandSizing.spaceSm),
        ],
        FilledButton.icon(
          onPressed: () => OfferSheet.open(context, job: job),
          icon: const Icon(Icons.local_offer_outlined),
          label: Text(hasOpenBid ? strings.changeMyOffer : strings.offerAFare),
        ),
      ],
    );
  }
}
