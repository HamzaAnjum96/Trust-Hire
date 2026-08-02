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
import '../../widgets/fading_row.dart';
import '../../widgets/meta_chip.dart';
import '../../widgets/state_views.dart';
import '../account/account_switcher.dart';
import '../map/location_controller.dart';
import '../premium/premium_rules.dart';
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
///
/// **And it is location-first, like the map.** A worker says how far they will
/// travel; this only shows the ones who would come. That rule
/// ([PremiumRules.reaches]) was written and tested when Mode B was built, and
/// then had no callers for two sprints, because no listing recorded where its
/// worker was — so a barber in Karachi appeared to a hirer in Peshawar with
/// "travels up to 10 km" written underneath.
class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final TextEditingController _search = TextEditingController();

  JobTag? _tag;
  DirectoryOrder _order = DirectoryOrder.byName;

  /// On by default. The premise of the product is that distance matters, and a
  /// directory that opens on everybody in the country makes the hirer do the
  /// filtering the app exists to do. It is a switch rather than a law because
  /// somebody booking a lawyer, or planning ahead for another city, has a
  /// perfectly good reason to look wider.
  bool _withinReach = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final premium = context.watch<PremiumController>();
    final jobs = context.watch<JobController>();
    final here = context.watch<LocationController>().position;

    final available = premium.directoryTags;
    // A filter for a category nobody offers is a dead end dressed as a
    // choice, so the row only ever shows tags with somebody behind them.
    final tag = available.contains(_tag) ? _tag : null;
    final query = _search.text;

    final names = <String, String>{
      for (final listing in premium.directory(onlyWithinReach: false))
        listing.workerId: ?jobs.userById(listing.workerId)?.name,
    };

    final listings = premium.directory(
      tag: tag,
      hirerAt: here,
      onlyWithinReach: _withinReach,
      order: _order,
      query: query,
      names: names,
    );

    // Whether anything was filtered *out*, which decides which empty state to
    // show: "nobody does this" and "your search found nothing" are different
    // problems with different ways out.
    final isFiltered = query.trim().isNotEmpty || tag != null;

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

            // Typing is the last resort in this product — the chips above and
            // the map are meant to carry most of the work — but the directory
            // is the one surface where somebody arrives knowing the name of
            // the person or the thing they want.
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: strings.searchDirectory,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: strings.clear,
                        onPressed: () => setState(_search.clear),
                      ),
                border: const OutlineInputBorder(
                  borderRadius: BrandRadius.mediumAll,
                ),
              ),
            ),

            const SizedBox(height: BrandSizing.spaceMd),

            // Same treatment as the job filters: eight categories do not fit
            // a phone, and a chip clipped mid-word by the screen edge reads as
            // a rendering bug rather than as a row that scrolls.
            if (available.isNotEmpty)
              FadingRow(
                padding: EdgeInsets.zero,
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

            const SizedBox(height: BrandSizing.spaceSm),

            _DirectoryControls(
              count: listings.length,
              order: _order,
              // Sorting by distance from a position nobody knows would be a
              // list in a made-up order with a confident label on it.
              canSortByDistance: here != null,
              onOrder: (value) => setState(() => _order = value),
              withinReach: _withinReach,
              onWithinReach: (value) => setState(() => _withinReach = value),
            ),

            const SizedBox(height: BrandSizing.spaceMd),

            if (listings.isEmpty)
              EmptyView(
                icon: isFiltered ? Icons.search_off : Icons.badge_outlined,
                title: isFiltered
                    ? strings.directoryNoMatch
                    : strings.directoryEmpty,
                message: isFiltered
                    ? strings.directoryNoMatchMessage
                    : strings.directoryEmptyMessage,
              )
            else
              for (final listing in listings) ...[
                _ListingCard(
                  listing: listing,
                  name: names[listing.workerId],
                  distanceMetres: premium.distanceTo(listing, hirerAt: here),
                ),
                const SizedBox(height: BrandSizing.spaceSm + 4),
              ],
          ],
        ),
      ),
    );
  }
}

/// How many people matched, and the two ways to change that.
///
/// Kept together in one row because they answer one question between them —
/// *am I looking at the right set?* — and split across the screen they read as
/// unrelated switches.
class _DirectoryControls extends StatelessWidget {
  const _DirectoryControls({
    required this.count,
    required this.order,
    required this.canSortByDistance,
    required this.onOrder,
    required this.withinReach,
    required this.onWithinReach,
  });

  final int count;
  final DirectoryOrder order;
  final bool canSortByDistance;
  final ValueChanged<DirectoryOrder> onOrder;
  final bool withinReach;
  final ValueChanged<bool> onWithinReach;

  String _label(AppStrings strings, DirectoryOrder value) => switch (value) {
    DirectoryOrder.byName => strings.directoryOrderByName,
    DirectoryOrder.byDistance => strings.directoryOrderByDistance,
    DirectoryOrder.byPrice => strings.directoryOrderByPrice,
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap rather than Row: "Cheapest first" beside a count does not fit
        // on a 320px phone, and in Urdu it does not fit on a 390px one.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: BrandSizing.spaceSm,
          runSpacing: BrandSizing.spaceXs,
          children: [
            // Say how many, so a short list reads as an answer rather than as
            // a screen that failed to load.
            Text(
              strings.directoryCount(count),
              style: theme.textTheme.labelLarge,
            ),
            PopupMenuButton<DirectoryOrder>(
              initialValue: order,
              onSelected: onOrder,
              tooltip: strings.directoryOrderLabel,
              itemBuilder: (context) => [
                for (final value in DirectoryOrder.values)
                  PopupMenuItem(
                    value: value,
                    // Offered but disabled, rather than hidden: a control that
                    // appears once location is granted is one nobody knows to
                    // look for.
                    enabled:
                        value != DirectoryOrder.byDistance ||
                        canSortByDistance,
                    child: Text(_label(strings, value)),
                  ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label(strings, order),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.primary,
                    semanticLabel: strings.directoryOrderLabel,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Not a Switch in a settings row: this changes what the list *is*, so
        // it sits with the list rather than somewhere the hirer has to
        // remember visiting.
        Row(
          children: [
            Checkbox(
              value: withinReach,
              onChanged: (value) => onWithinReach(value ?? true),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onWithinReach(!withinReach),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: BrandSizing.spaceSm,
                  ),
                  child: Text(
                    strings.directoryWithinReach,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Only when it is off, and only as a statement of fact. A hirer who
        // widened the net deliberately does not need talking out of it.
        if (!withinReach)
          Padding(
            padding: const EdgeInsets.only(left: BrandSizing.spaceMd),
            child: Text(
              strings.directoryWithinReachOff,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// One worker, as a row in the directory.
///
/// Name, one line, what they start at, and their record. Deliberately not a
/// photograph and not a badge: Section 9 sells *visibility*, and anything that
/// made a paid listing look endorsed would be selling something else.
class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    this.name,
    this.distanceMetres,
  });

  final DirectoryListing listing;
  final String? name;

  /// How far away this worker is, when both ends have said. Null is shown as
  /// nothing at all rather than as "unknown", which would be a row of noise
  /// on every card the moment somebody declines location.
  final double? distanceMetres;

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

              // How far, and how far they will come. The second is the number
              // the worker chose, and it is the reason they are on this
              // screen at all rather than a different one.
              const SizedBox(height: BrandSizing.spaceSm),
              Wrap(
                spacing: BrandSizing.spaceMd,
                runSpacing: BrandSizing.spaceXs,
                children: [
                  if (distanceMetres != null)
                    MetaChip(
                      icon: Icons.near_me_outlined,
                      label: Format.distance(strings, distanceMetres!),
                    ),
                  MetaChip(
                    icon: listing.remoteOnly
                        ? Icons.language
                        : Icons.directions_car_outlined,
                    label: listing.remoteOnly
                        ? strings.worksRemotely
                        : strings.travelsUpTo(
                            Format.span(strings, listing.serviceRadiusMetres),
                          ),
                  ),
                ],
              ),

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
