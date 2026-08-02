import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/premium_controller.dart';
import '../../core/formatters.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job_tag.dart';
import '../../models/premium.dart';
import '../map/location_controller.dart';
import '../../widgets/state_views.dart';

/// The worker's side of Mode B: pay to be listed, then say what you do and
/// what you charge.
///
/// **The subscription is not the first thing asked for.** A worker can build
/// their menu, write their line and set their radius before spending anything,
/// and only then decide whether being found is worth the money. A screen that
/// leads with a price asks somebody to buy before they know what they are
/// buying — and this audience is being asked to spend real money on a promise.
class MyListingScreen extends StatelessWidget {
  const MyListingScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const MyListingScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final premium = context.watch<PremiumController>();
    final listing = premium.mine;

    return Scaffold(
      appBar: AppBar(title: Text(strings.myListing)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BrandSizing.spaceMd,
            BrandSizing.spaceMd,
            BrandSizing.spaceMd,
            BrandSizing.spaceXl * 2,
          ),
          children: [
            const _SubscriptionPanel(),

            const SizedBox(height: BrandSizing.spaceXl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.serviceMenu,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _ServiceSheet.open(context),
                  icon: const Icon(Icons.add),
                  label: Text(strings.addService),
                ),
              ],
            ),

            if (listing.services.isEmpty)
              EmptyView(
                icon: Icons.sell_outlined,
                title: strings.noServicesYet,
                message: strings.noServicesYetMessage,
              )
            else
              for (final service in listing.services)
                _ServiceRow(service: service),

            // Only worth saying once there is a subscription to be wasted by
            // an empty menu.
            if (premium.isPremium && listing.services.isEmpty) ...[
              const SizedBox(height: BrandSizing.spaceSm),
              NoticePanel(message: strings.listingNeedsService),
            ],

            const SizedBox(height: BrandSizing.spaceXl),
            Text(
              strings.serviceAreaHeading,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: BrandSizing.spaceSm),
            const _ServiceArea(),

            const SizedBox(height: BrandSizing.spaceXl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.credentialsHeading,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _CredentialSheet.open(context),
                  icon: const Icon(Icons.add),
                  label: Text(strings.addCredential),
                ),
              ],
            ),
            Text(
              strings.credentialsUnverified,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BrandSizing.spaceSm),
            for (final credential in listing.credentials)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(credential.title),
                subtitle: credential.issuer == null
                    ? null
                    : Text(credential.issuer!),
                trailing: IconButton(
                  tooltip: strings.removeService,
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      premium.removeCredential(credential.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// What being listed costs, and what it buys.
class _SubscriptionPanel extends StatelessWidget {
  const _SubscriptionPanel();

  Future<void> _subscribe(BuildContext context, SubscriptionPlan plan) async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await context.read<PremiumController>().subscribe(plan);

    messenger.showSnackBar(SnackBar(content: Text(strings.premiumStarted)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final premium = context.watch<PremiumController>();
    final subscription = premium.mine.subscription;
    final rules = premium.rules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.premiumHeading, style: theme.textTheme.titleLarge),
        const SizedBox(height: BrandSizing.spaceXs),
        Text(strings.premiumPitch, style: theme.textTheme.bodyMedium),

        if (premium.isPremium && subscription != null) ...[
          const SizedBox(height: BrandSizing.spaceMd),
          NoticePanel(
            message:
                '${strings.premiumActive(Format.day(strings, subscription.expiresAt))} · '
                '${strings.premiumDaysLeft(subscription.daysLeftAt(DateTime.now()))}',
            icon: Icons.verified_outlined,
          ),
        ] else if (premium.hasLapsed) ...[
          const SizedBox(height: BrandSizing.spaceMd),
          // Section 9's lapse handling, said plainly. The two things that did
          // *not* happen matter more than the one that did.
          NoticePanel(message: strings.premiumLapsed),
        ],

        const SizedBox(height: BrandSizing.spaceMd),
        Row(
          spacing: BrandSizing.spaceSm,
          children: [
            for (final plan in SubscriptionPlan.values)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _subscribe(context, plan),
                  child: Column(
                    children: [
                      Text(
                        plan == SubscriptionPlan.monthly
                            ? strings.premiumMonthly
                            : strings.premiumYearly,
                        style: BrandType.button,
                      ),
                      Text(
                        Format.fare(strings, rules.priceOf(plan)),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: BrandSizing.spaceSm),
        // The same promise the wallet's top-up screen makes. A page that looks
        // like a payment form without being one is the shape of a scam, and a
        // product about trust cannot teach people that Trust Hire asks for
        // card numbers.
        Text(
          strings.premiumSimulated,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final ServiceOffering service;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final premium = context.read<PremiumController>();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(service.tag.icon),
      title: Text(service.title),
      subtitle: Text(Format.fare(strings, service.priceRupees)),
      trailing: IconButton(
        tooltip: strings.removeService,
        icon: const Icon(Icons.close),
        onPressed: () => premium.removeService(service.id),
      ),
    );
  }
}

/// How far this worker will travel — Section 9's own mechanism, separate from
/// the job-centered geofence in Mode A.
class _ServiceArea extends StatelessWidget {
  const _ServiceArea();

  /// The distances offered, with the default among them.
  ///
  /// It has to be: a worker who has never touched this has
  /// [DirectoryListing.defaultServiceRadiusMetres], and a row of chips with
  /// none of them selected tells them their radius is unset when it is not.
  static const _options = <double>[
    3000,
    DirectoryListing.defaultServiceRadiusMetres,
    20000,
    40000,
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final premium = context.watch<PremiumController>();
    final location = context.watch<LocationController>();
    final listing = premium.mine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: listing.remoteOnly,
          title: Text(strings.remoteOnlyLabel),
          onChanged: (value) => premium.setServiceArea(remoteOnly: value),
        ),
        if (!listing.remoteOnly) ...[
          // **Where the radius is measured from.** Without it the number
          // below is decorative: "I travel 12 km" from nowhere in particular
          // cannot exclude anybody, so the listing shows to the whole country
          // and the worker gets enquiries from four provinces away.
          const SizedBox(height: BrandSizing.spaceSm),
          Text(strings.whereYouWorkFrom, style: theme.textTheme.titleSmall),
          const SizedBox(height: BrandSizing.spaceXs),
          Text(
            strings.whereYouWorkFromHelp,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BrandSizing.spaceXs),
          Row(
            children: [
              Icon(
                listing.base == null
                    ? Icons.location_off_outlined
                    : Icons.place_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: BrandSizing.spaceSm),
              Expanded(
                child: Text(
                  listing.base == null
                      ? strings.workFromNotSet
                      : strings.workFromSet,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: BrandSizing.spaceXs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: location.isRequesting
                  ? null
                  : () async {
                      await location.request();
                      final position = location.position;
                      if (position == null || !context.mounted) return;
                      await premium.setServiceArea(base: position);
                    },
              icon: const Icon(Icons.my_location, size: 18),
              label: Text(strings.useMyLocation),
            ),
          ),

          const SizedBox(height: BrandSizing.spaceMd),
          Text(strings.howFarYouTravel),
          const SizedBox(height: BrandSizing.spaceXs),
          Wrap(
            spacing: BrandSizing.spaceSm,
            runSpacing: BrandSizing.spaceXs,
            children: [
              // The presets, plus whatever this worker actually has if it is
              // not one of them — the seeded listings carry distances a
              // person picked rather than a menu offered, and dropping their
              // own figure off the row would make the control look like it
              // had forgotten.
              for (final metres in {
                ..._options,
                listing.serviceRadiusMetres,
              }.toList()..sort())
                ChoiceChip(
                  label: Text(Format.distance(strings, metres)),
                  selected: listing.serviceRadiusMetres == metres,
                  onSelected: (_) =>
                      premium.setServiceArea(radiusMetres: metres),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Adding one thing to the menu.
class _ServiceSheet extends StatefulWidget {
  const _ServiceSheet();

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ServiceSheet(),
  );

  @override
  State<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<_ServiceSheet> {
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  JobTag _tag = JobTag.misc;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      _title.text.trim().isNotEmpty && (int.tryParse(_price.text) ?? 0) > 0;

  Future<void> _save() async {
    final navigator = Navigator.of(context);

    await context.read<PremiumController>().addService(
      tag: _tag,
      title: _title.text,
      priceRupees: int.parse(_price.text),
      description: _description.text,
    );

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          BrandSizing.spaceMd,
          0,
          BrandSizing.spaceMd,
          BrandSizing.spaceMd + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.addService,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: BrandSizing.spaceMd),

              TextField(
                controller: _title,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: strings.serviceTitleLabel,
                  border: const OutlineInputBorder(
                    borderRadius: BrandRadius.mediumAll,
                  ),
                ),
              ),
              const SizedBox(height: BrandSizing.spaceSm),

              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: strings.servicePriceLabel,
                  hintText: strings.fareHint,
                  border: const OutlineInputBorder(
                    borderRadius: BrandRadius.mediumAll,
                  ),
                ),
              ),
              const SizedBox(height: BrandSizing.spaceSm),

              TextField(
                controller: _description,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: strings.serviceDescriptionLabel,
                  border: const OutlineInputBorder(
                    borderRadius: BrandRadius.mediumAll,
                  ),
                ),
              ),

              const SizedBox(height: BrandSizing.spaceMd),
              Text(strings.serviceKindLabel),
              const SizedBox(height: BrandSizing.spaceXs),
              Wrap(
                spacing: BrandSizing.spaceXs,
                runSpacing: BrandSizing.spaceXs,
                children: [
                  for (final option in JobTag.workerOrder)
                    ChoiceChip(
                      avatar: Icon(option.icon, size: 16),
                      label: Text(option.label(strings)),
                      selected: _tag == option,
                      onSelected: (_) => setState(() => _tag = option),
                    ),
                ],
              ),

              const SizedBox(height: BrandSizing.spaceMd),
              FilledButton(
                onPressed: _isComplete ? _save : null,
                child: Text(strings.saveService),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Adding one claim to the showcase.
class _CredentialSheet extends StatefulWidget {
  const _CredentialSheet();

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _CredentialSheet(),
  );

  @override
  State<_CredentialSheet> createState() => _CredentialSheetState();
}

class _CredentialSheetState extends State<_CredentialSheet> {
  final _title = TextEditingController();
  final _issuer = TextEditingController();
  final _year = TextEditingController();
  CredentialKind _kind = CredentialKind.qualification;

  @override
  void dispose() {
    _title.dispose();
    _issuer.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);

    await context.read<PremiumController>().addCredential(
      kind: _kind,
      title: _title.text,
      issuer: _issuer.text,
      year: int.tryParse(_year.text),
    );

    navigator.pop();
  }

  String _label(AppStrings strings, CredentialKind kind) => switch (kind) {
    CredentialKind.qualification => strings.credentialKindQualification,
    CredentialKind.certification => strings.credentialKindCertification,
    CredentialKind.experience => strings.credentialKindExperience,
    CredentialKind.membership => strings.credentialKindMembership,
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          BrandSizing.spaceMd,
          0,
          BrandSizing.spaceMd,
          BrandSizing.spaceMd + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.addCredential,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: BrandSizing.spaceMd),

              TextField(
                controller: _title,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: strings.credentialTitleLabel,
                  border: const OutlineInputBorder(
                    borderRadius: BrandRadius.mediumAll,
                  ),
                ),
              ),
              const SizedBox(height: BrandSizing.spaceSm),
              TextField(
                controller: _issuer,
                decoration: InputDecoration(
                  labelText: strings.credentialIssuerLabel,
                  border: const OutlineInputBorder(
                    borderRadius: BrandRadius.mediumAll,
                  ),
                ),
              ),
              const SizedBox(height: BrandSizing.spaceSm),
              TextField(
                controller: _year,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: strings.credentialYearLabel,
                  border: const OutlineInputBorder(
                    borderRadius: BrandRadius.mediumAll,
                  ),
                ),
              ),

              const SizedBox(height: BrandSizing.spaceMd),
              Wrap(
                spacing: BrandSizing.spaceXs,
                children: [
                  for (final kind in CredentialKind.values)
                    ChoiceChip(
                      label: Text(_label(strings, kind)),
                      selected: _kind == kind,
                      onSelected: (_) => setState(() => _kind = kind),
                    ),
                ],
              ),

              const SizedBox(height: BrandSizing.spaceMd),
              FilledButton(
                onPressed: _title.text.trim().isEmpty ? null : _save,
                child: Text(strings.saveService),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
