import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../app/account_controller.dart';
import '../../app/job_controller.dart';
import '../../app/premium_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../models/premium.dart';
import '../../services/location_service.dart';
import '../../widgets/state_views.dart';
import '../map/location_controller.dart';

/// Booking a fixed-price service, and the one screen where the hirer's
/// discount has to be legible.
///
/// Section 9's leakage argument only works if the hirer can *see* that booking
/// in the app is cheaper than ringing the same worker directly. So this shows
/// the worker's own price, what the hirer pays, the difference, and who is
/// paying for it — rather than quietly showing a smaller number and hoping
/// nobody compares.
class BookingSheet extends StatefulWidget {
  const BookingSheet({
    super.key,
    required this.listing,
    required this.service,
    required this.workerName,
  });

  final DirectoryListing listing;
  final ServiceOffering service;
  final String workerName;

  static Future<void> open(
    BuildContext context, {
    required DirectoryListing listing,
    required ServiceOffering service,
    required String workerName,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BookingSheet(
      listing: listing,
      service: service,
      workerName: workerName,
    ),
  );

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  bool _sending = false;

  Future<void> _book() async {
    if (_sending) return;
    setState(() => _sending = true);

    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final premium = context.read<PremiumController>();
    final jobs = context.read<JobController>();
    final me = context.read<AccountController>().activeId;
    final at =
        context.read<LocationController>().position ?? LocationService.fallback;

    // Checked again here rather than trusting the screen behind this. A
    // subscription can lapse while somebody reads a menu, and the price and
    // the radius were part of a live offer — holding a worker to terms they
    // have stopped offering is not a booking, it is a trap.
    final live = premium.listingFor(widget.listing.workerId);
    final allowed =
        live != null &&
        premium.rules.canBook(
          live,
          service: widget.service,
          now: DateTime.now(),
        );

    if (!allowed) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(strings.bookingUnavailable)),
      );
      return;
    }

    final listed = widget.service.priceRupees;

    await jobs.saveJob(
      Job(
        id: const Uuid().v4(),
        location: at,
        createdAt: DateTime.now(),
        title: widget.service.title,
        tags: {widget.service.tag},
        shortDescription: widget.service.description,
        // Section 9: not broadcast. JobVisibility sends this to one person and
        // to nobody else.
        bookedWorkerId: widget.listing.workerId,
        listedFare: listed,
        // Fixed at booking rather than at acceptance, because Mode B is not
        // negotiated — the hirer saw this number and agreed to it before the
        // worker was ever asked.
        agreedFare: premium.rules.priceForHirer(listed),
        postedBy: me,
        isLocal: true,
      ),
    );

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(strings.bookingSent(widget.workerName))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final rules = context.read<PremiumController>().rules;

    final listed = widget.service.priceRupees;
    final youPay = rules.priceForHirer(listed);
    final saving = listed - youPay;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BrandSizing.spaceMd,
          0,
          BrandSizing.spaceMd,
          BrandSizing.spaceMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.bookingTitle(widget.service.title),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: BrandSizing.spaceMd),

            _PriceRow(
              label: strings.bookingListPrice,
              amount: Format.fare(strings, listed),
            ),
            _PriceRow(
              label: strings.bookingYouPay,
              amount: Format.fare(strings, youPay),
              emphasised: true,
            ),

            if (saving > 0) ...[
              const SizedBox(height: BrandSizing.spaceSm),
              NoticePanel(
                message:
                    '${strings.bookingSaving(Format.fare(strings, saving))} '
                    '${strings.bookingDiscountWhy}',
                icon: Icons.savings_outlined,
              ),
            ],

            const SizedBox(height: BrandSizing.spaceMd),
            Text(
              strings.bookingWhatNext,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: BrandSizing.spaceMd),
            FilledButton(
              onPressed: _sending ? null : _book,
              // Section 21 — say what the action does, never "Confirm".
              child: Text(strings.bookingConfirm),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.emphasised = false,
  });

  final String label;
  final String amount;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BrandSizing.spaceXs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            amount,
            style: emphasised
                ? theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
        ],
      ),
    );
  }
}
