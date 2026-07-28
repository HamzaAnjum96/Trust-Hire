import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../app/premium_controller.dart';
import '../../core/formatters.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/premium.dart';
import '../../widgets/state_views.dart';
import '../ratings/worker_standing_view.dart';
import 'booking_sheet.dart';

/// One worker's page in the directory: what they do, what it costs, what they
/// say about themselves, and what their customers said.
///
/// The order is deliberate. The record comes before the credentials, because
/// a rating is evidence and a credential is a claim — and putting the claim
/// first would let a well-written listing outrank a well-reviewed worker.
class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key, required this.workerId});

  final String workerId;

  static Future<void> open(
    BuildContext context, {
    required DirectoryListing listing,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WorkerProfileScreen(workerId: listing.workerId),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final premium = context.watch<PremiumController>();
    final jobs = context.watch<JobController>();

    final listing = premium.listingFor(workerId);
    final name = jobs.userById(workerId)?.name ?? strings.someone;

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(title: Text(name)),
        body: EmptyView(
          icon: Icons.badge_outlined,
          title: strings.directoryEmpty,
          message: strings.bookingUnavailable,
        ),
      );
    }

    // Read live rather than captured when the card was tapped: a subscription
    // can lapse while somebody is reading, and the booking sheet checks the
    // same thing again before it writes anything.
    final isListed = premium.rules.appearsInDirectory(
      listing,
      now: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BrandSizing.spaceMd,
            BrandSizing.spaceMd,
            BrandSizing.spaceMd,
            BrandSizing.spaceXl * 2,
          ),
          children: [
            if (listing.headline != null) ...[
              Text(listing.headline!, style: theme.textTheme.titleMedium),
              const SizedBox(height: BrandSizing.spaceMd),
            ],

            WorkerStandingView(workerId: workerId),

            const SizedBox(height: BrandSizing.spaceLg),
            Text(strings.serviceAreaHeading, style: theme.textTheme.titleMedium),
            const SizedBox(height: BrandSizing.spaceXs),
            Text(
              listing.remoteOnly
                  ? strings.serviceAreaRemote
                  : strings.serviceAreaRadius(
                      Format.distance(strings, listing.serviceRadiusMetres),
                    ),
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: BrandSizing.spaceLg),
            Text(strings.serviceMenu, style: theme.textTheme.titleLarge),
            const SizedBox(height: BrandSizing.spaceSm),

            if (!isListed)
              NoticePanel(message: strings.bookingUnavailable)
            else
              for (final service in listing.services) ...[
                _ServiceCard(listing: listing, service: service, name: name),
                const SizedBox(height: BrandSizing.spaceSm),
              ],

            if (listing.credentials.isNotEmpty) ...[
              const SizedBox(height: BrandSizing.spaceLg),
              Text(
                strings.credentialsHeading,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: BrandSizing.spaceXs),
              // Said once, above the list rather than on each row. Section 2
              // verifies a CNIC and a phone number; it does not verify a
              // degree, and showing an unchecked claim without this line
              // would be the app vouching for something nobody checked.
              Text(
                strings.credentialsUnverified,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: BrandSizing.spaceSm),
              for (final credential in listing.credentials)
                _CredentialRow(credential: credential),
            ],
          ],
        ),
      ),
    );
  }
}

/// One thing on the menu, at one price, with the way to book it.
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.listing,
    required this.service,
    required this.name,
  });

  final DirectoryListing listing;
  final ServiceOffering service;
  final String name;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final rules = context.read<PremiumController>().rules;

    final youPay = rules.priceForHirer(service.priceRupees);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BrandRadius.mediumAll,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(service.tag.icon, size: 20),
                const SizedBox(width: BrandSizing.spaceSm),
                Expanded(
                  child: Text(
                    service.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),

            if (service.description != null) ...[
              const SizedBox(height: BrandSizing.spaceXs),
              Text(service.description!, style: theme.textTheme.bodyMedium),
            ],

            const SizedBox(height: BrandSizing.spaceSm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Format.fare(strings, youPay),
                        style: theme.textTheme.titleLarge,
                      ),
                      // The saving is shown, not just the smaller number. A
                      // discount nobody can see does not stop anybody taking
                      // the worker's number and booking them off-platform,
                      // which is the entire point of it.
                      if (youPay != service.priceRupees)
                        Text(
                          strings.bookingSaving(
                            Format.fare(
                              strings,
                              service.priceRupees - youPay,
                            ),
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: BrandColours.successTeal,
                          ),
                        ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => BookingSheet.open(
                    context,
                    listing: listing,
                    service: service,
                    workerName: name,
                  ),
                  child: Text(strings.bookThis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.credential});

  final WorkerCredential credential;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    final detail = [
      switch (credential.kind) {
        CredentialKind.qualification => strings.credentialKindQualification,
        CredentialKind.certification => strings.credentialKindCertification,
        CredentialKind.experience => strings.credentialKindExperience,
        CredentialKind.membership => strings.credentialKindMembership,
      },
      if (credential.issuer != null) credential.issuer!,
      if (credential.year != null) '${credential.year}',
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.workspace_premium_outlined),
      title: Text(credential.title),
      subtitle: Text(detail),
    );
  }
}
