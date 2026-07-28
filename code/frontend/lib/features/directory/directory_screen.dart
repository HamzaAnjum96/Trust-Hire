import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../app/premium_controller.dart';
import '../../core/formatters.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job_tag.dart';
import '../../models/premium.dart';
import '../../widgets/state_views.dart';
import '../account/account_switcher.dart';
import '../ratings/worker_standing_view.dart';
import 'worker_profile_screen.dart';

/// Mode B: the people, rather than the work.
///
/// Section 9's "second, parallel discovery mode". The map answers *where is
/// there work*; this answers *who can do this, and what do they charge*. They
/// are different questions, which is why this is a destination of its own
/// rather than a filter on the map — a barber is not a job, and folding them
/// into one list would make both worse.
///
/// **No haggling here, by design.** Every price is fixed and visible before
/// anybody commits. A professional who charges Rs. 1,500 for a consultation
/// should not have to defend that number to each enquiry, which is the whole
/// reason Mode B exists alongside bidding rather than replacing it.
class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  JobTag? _tag;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final premium = context.watch<PremiumController>();
    final jobs = context.watch<JobController>();

    final available = premium.directoryTags;
    // A filter for a category nobody offers is a dead end dressed as a
    // choice, so the row only ever shows tags with somebody behind them.
    final tag = available.contains(_tag) ? _tag : null;
    final listings = premium.directory(tag: tag);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.directoryTitle),
        actions: const [AccountButton()],
      ),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BrandSizing.spaceMd,
            BrandSizing.spaceMd,
            BrandSizing.spaceMd,
            BrandSizing.spaceXl * 3,
          ),
          children: [
            Text(
              strings.directoryIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BrandSizing.spaceMd),

            if (available.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: BrandSizing.spaceSm,
                  children: [
                    ChoiceChip(
                      label: Text(strings.directoryAllWork),
                      selected: tag == null,
                      onSelected: (_) => setState(() => _tag = null),
                    ),
                    for (final option in JobTag.workerOrder)
                      if (available.contains(option))
                        ChoiceChip(
                          avatar: Icon(option.icon, size: 18),
                          label: Text(option.label(strings)),
                          selected: tag == option,
                          onSelected: (_) => setState(() => _tag = option),
                        ),
                  ],
                ),
              ),

            const SizedBox(height: BrandSizing.spaceMd),

            if (listings.isEmpty)
              EmptyView(
                icon: Icons.badge_outlined,
                title: strings.directoryEmpty,
                message: strings.directoryEmptyMessage,
              )
            else
              for (final listing in listings) ...[
                _ListingCard(
                  listing: listing,
                  name: jobs.userById(listing.workerId)?.name,
                ),
                const SizedBox(height: BrandSizing.spaceSm + 4),
              ],
          ],
        ),
      ),
    );
  }
}

/// One worker, as a row in the directory.
///
/// Name, one line, what they start at, and their record. Deliberately not a
/// photograph and not a badge: Section 9 sells *visibility*, and anything that
/// made a paid listing look endorsed would be selling something else.
class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, this.name});

  final DirectoryListing listing;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final from = listing.fromPrice;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BrandRadius.mediumAll,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BrandRadius.mediumAll,
        onTap: () => WorkerProfileScreen.open(context, listing: listing),
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
                      name ?? strings.someone,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (from != null)
                    Text(
                      strings.fromPrice(Format.fare(strings, from)),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),

              if (listing.headline != null) ...[
                const SizedBox(height: BrandSizing.spaceXs),
                Text(listing.headline!, style: theme.textTheme.bodyMedium),
              ],

              const SizedBox(height: BrandSizing.spaceSm),
              Wrap(
                spacing: BrandSizing.spaceXs,
                runSpacing: BrandSizing.spaceXs,
                children: [
                  for (final tag in listing.tags)
                    Chip(
                      avatar: Icon(tag.icon, size: 16),
                      label: Text(tag.label(strings)),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),

              const SizedBox(height: BrandSizing.spaceXs),
              WorkerStandingView(workerId: listing.workerId, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
