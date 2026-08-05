import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/bid_controller.dart';
import '../../app/job_controller.dart';
import '../../app/notification_controller.dart';
import '../../app/premium_controller.dart';
import '../../app/rating_controller.dart';
import '../../app/verification_controller.dart';
import '../../app/wallet_controller.dart';
import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../models/notification.dart';
import '../../services/media_store.dart';
import '../../widgets/state_views.dart';
import '../jobs/job_details_sheet.dart';

/// What happened, newest first.
///
/// The one screen in the app that is entirely derived — nothing here is stored
/// except the mark saying how far the reader had got. See [NotificationRules]
/// for why.
class UpdatesTab extends StatefulWidget {
  const UpdatesTab({super.key});

  @override
  State<UpdatesTab> createState() => _UpdatesTabState();
}

class _UpdatesTabState extends State<UpdatesTab> {
  @override
  void initState() {
    super.initState();
    // Opening the tab *is* reading it. Deferred a frame because this runs
    // during the first build and marking seen notifies listeners.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationController>().markSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final notifications = context.watch<NotificationController>();
    final jobs = context.watch<JobController>();

    final feed = buildFeed(context);
    if (feed.isEmpty) {
      return EmptyView(
        icon: Icons.notifications_none,
        title: strings.updatesEmpty,
        message: strings.updatesEmptyMessage,
      );
    }

    final seenAt = notifications.seenAt;
    final byId = {for (final job in jobs.jobs) job.id: job};

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceXl * 3,
      ),
      itemCount: feed.length,
      separatorBuilder: (_, _) => const SizedBox(height: BrandSizing.spaceSm),
      itemBuilder: (context, index) {
        final entry = feed[index];

        return _UpdateCard(
          entry: entry,
          job: entry.jobId == null ? null : byId[entry.jobId],
          // Highlighted only on the pass where it was still unseen. The mark
          // moves a frame after the tab opens, so the reader gets one look at
          // what is new rather than a list that was already grey.
          isNew: seenAt != null && entry.at.isAfter(seenAt),
        );
      },
    );
  }
}

/// The feed for whoever is signed in.
///
/// A free function because the shell needs the same list to work out the badge
/// and must not build a tab to get it.
List<AppNotification> buildFeed(BuildContext context) {
  final notifications = context.watch<NotificationController>();
  final jobs = context.watch<JobController>();
  final bids = context.watch<BidController>();
  final ratings = context.watch<RatingController>();
  final wallet = context.watch<WalletController>();
  final premium = context.watch<PremiumController>();
  final verification = context.watch<VerificationController>();

  return notifications.feed(
    jobs: jobs.jobs,
    bids: bids.bids,
    ratings: ratings.all,
    wallet: wallet.wallet,
    listing: premium.mine,
    review: verification.review,
    walletLocked: wallet.isLockedOut,
  );
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.entry, required this.isNew, this.job});

  final AppNotification entry;
  final Job? job;
  final bool isNew;

  /// One icon per kind, chosen so the list can be scanned without reading it.
  (IconData, Color) _glyph(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return switch (entry.kind) {
      NotificationKind.offerReceived => (Icons.local_offer_outlined,
        scheme.primary),
      NotificationKind.offerAccepted => (Icons.check_circle_outline,
        BrandColours.successTeal),
      NotificationKind.offerPassedOver => (Icons.do_not_disturb_on_outlined,
        scheme.outline),
      NotificationKind.jobStarted => (Icons.play_circle_outline,
        scheme.primary),
      NotificationKind.jobCompleted => (Icons.task_alt,
        BrandColours.successTeal),
      NotificationKind.jobCancelled => (Icons.cancel_outlined, scheme.outline),
      NotificationKind.jobExpired => (Icons.timer_off_outlined, scheme.outline),
      NotificationKind.ratingReceived => (Icons.star_outline, scheme.primary),
      NotificationKind.commissionCharged => (Icons.receipt_long_outlined,
        scheme.onSurfaceVariant),
      NotificationKind.walletCredited => (Icons.account_balance_wallet_outlined,
        BrandColours.successTeal),
      NotificationKind.walletLocked => (Icons.lock_outline, scheme.error),
      NotificationKind.subscriptionExpiring => (Icons.schedule,
        BrandColours.informationBlue),
      NotificationKind.subscriptionLapsed => (Icons.badge_outlined,
        scheme.error),
      NotificationKind.verificationApproved => (Icons.verified_outlined,
        BrandColours.successTeal),
      NotificationKind.verificationRejected => (Icons.gpp_bad_outlined,
        scheme.error),
    };
  }

  String _line(BuildContext context, AppStrings strings) {
    final money = entry.amount == null
        ? ''
        : Format.fare(strings, entry.amount!);

    return switch (entry.kind) {
      NotificationKind.offerReceived => strings.notifOfferReceived(
        context.read<JobController>().userById(entry.otherPartyId ?? '')?.name ??
            strings.someone,
        money,
      ),
      NotificationKind.offerAccepted => strings.notifOfferAccepted(money),
      NotificationKind.offerPassedOver => strings.notifOfferPassedOver,
      NotificationKind.jobStarted => strings.notifJobStarted,
      // The fare is worth repeating on completion — it is the moment somebody
      // checks what they are owed — but a job with no agreed fare has none to
      // repeat, and "finished at Rs. 0" would be a lie.
      NotificationKind.jobCompleted => entry.amount == null
          ? strings.notifJobCompleted
          : strings.notifJobCompletedFare(money),
      NotificationKind.jobCancelled => strings.notifJobCancelled,
      NotificationKind.jobExpired => strings.notifJobExpired,
      NotificationKind.ratingReceived => strings.notifRatingReceived(
        entry.stars ?? 0,
      ),
      NotificationKind.commissionCharged => strings.notifCommissionCharged(
        money,
      ),
      NotificationKind.walletCredited => strings.notifWalletCredited(money),
      NotificationKind.walletLocked => strings.notifWalletLocked,
      NotificationKind.subscriptionExpiring =>
        strings.notifSubscriptionExpiring,
      NotificationKind.subscriptionLapsed => strings.notifSubscriptionLapsed,
      NotificationKind.verificationApproved =>
        strings.notifVerificationApproved,
      NotificationKind.verificationRejected =>
        strings.notifVerificationRejected,
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final (icon, colour) = _glyph(context);
    final target = job;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BrandRadius.mediumAll,
        side: BorderSide(
          // The only thing marking an entry as new. Not a dot and not a bold
          // weight: this list is read at a glance, and a coloured edge survives
          // being glanced at.
          color: isNew ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: isNew ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BrandRadius.mediumAll,
        onTap: target == null
            ? null
            : () => JobDetailsSheet.open(
                context,
                jobId: target.id,
                mediaStore: context.read<MediaStore>(),
              ),
        child: Padding(
          padding: const EdgeInsets.all(BrandSizing.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colour, size: 22),
              const SizedBox(width: BrandSizing.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _line(context, strings),
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (target != null) ...[
                      const SizedBox(height: BrandSizing.spaceXs),
                      Text(
                        // What the update is *about*. Without it the list is a
                        // column of "Job finished" with no way to tell which.
                        target.title ?? target.area ?? strings.untitledJob,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: BrandSizing.spaceXs),
                    Text(
                      Format.posted(strings, entry.at, DateTime.now()),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (target != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.outline,
                  semanticLabel: strings.openDetails,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
