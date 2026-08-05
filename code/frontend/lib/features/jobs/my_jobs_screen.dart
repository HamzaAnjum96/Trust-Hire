import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/account_controller.dart';
import '../../app/bid_controller.dart';
import '../../app/job_controller.dart';
import '../../core/formatters.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../app/notification_controller.dart';
import '../../app/message_controller.dart';
import '../messaging/threads_tab.dart';
import '../notifications/updates_tab.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bid.dart';
import '../../models/job.dart';
import '../../services/media_store.dart';
import '../../widgets/job_skeleton.dart';
import '../../widgets/state_views.dart';
import 'job_details_sheet.dart';
import 'job_row.dart';
import 'saved_jobs_controller.dart';
import '../account/account_switcher.dart';

/// The three lists that are about *you* — work you kept, work you posted, and
/// work you offered on.
///
/// All three are answers to the same gap: the app had nowhere to come back to.
/// A worker who found a job had to find it again; a poster had no home for
/// what they had posted; and an offer, once made, could only be found by
/// remembering which job it was on — which meant a passed-over bid was
/// invisible, and being passed over is what happens to most of them.
class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final jobs = context.watch<JobController>();
    final saved = context.watch<SavedJobsController>();

    final savedJobs = saved.resolve(jobs.jobs);
    final me = context.watch<AccountController>().activeId;
    final myPostings = jobs.jobs.where((job) => job.isPostedBy(me)).toList();

    // Newest offer first, and only the ones whose job still exists — a bid on
    // a deleted job is a row with nothing behind it.
    final byId = {for (final job in jobs.jobs) job.id: job};
    final myOffers =
        (context
                .watch<BidController>()
                .bids
                .where((bid) => bid.workerId == me && byId[bid.jobId] != null)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
            .toList(growable: false);

    final unseen = context.watch<NotificationController>().unseen(
      buildFeed(context),
    );
    final waiting = context.watch<MessageController>().threadsWaiting(jobs.jobs);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.navActivity),
        actions: const [AccountButton()],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            // Updates first: it is the reason to open this destination at all
            // now, and the three lists behind it are things you go looking for
            // rather than things that change while you are away.
            Tab(text: unseen == 0
                ? strings.updatesTab
                : '${strings.updatesTab} · $unseen'),
            Tab(text: waiting == 0
                ? strings.messagesTab
                : '${strings.messagesTab} · $waiting'),
            Tab(text: '${strings.savedTab} · ${savedJobs.length}'),
            Tab(text: '${strings.postedTab} · ${myPostings.length}'),
            Tab(text: '${strings.offersTab} · ${myOffers.length}'),
          ],
        ),
      ),
      // The same measure as the job list; these are the same rows.
      body: ReadableWidth(
        child: switch (jobs.state) {
          LoadState.idle || LoadState.loading => const JobListSkeleton(),
          LoadState.failed => ErrorView(
            message: strings.couldNotLoadJobs,
            onRetry: jobs.load,
          ),
          LoadState.ready => TabBarView(
            controller: _tabs,
            children: [
              const UpdatesTab(),
              const ThreadsTab(),
              _JobsTab(
                jobs: savedJobs,
                emptyIcon: Icons.bookmark_border,
                emptyTitle: strings.noSavedJobs,
                emptyMessage: strings.noSavedJobsMessage,
                // Said once, rather than letting the list quietly shrink.
                notice: saved.hasMissing(jobs.jobs)
                    ? strings.savedJobGone
                    : null,
              ),
              _JobsTab(
                jobs: myPostings,
                emptyIcon: Icons.work_outline,
                emptyTitle: strings.noPostings,
                emptyMessage: strings.noPostingsMessage,
              ),
              _OffersTab(offers: myOffers, jobs: byId),
            ],
          ),
        },
      ),
    );
  }
}

/// Every offer this account has made, with what became of it.
///
/// The status is stated in words rather than left to be inferred from the
/// job's own state. "Not chosen" is the commonest outcome there is, and a
/// worker should be able to read it once and move on rather than open the job
/// to work out whether they are still waiting.
class _OffersTab extends StatelessWidget {
  const _OffersTab({required this.offers, required this.jobs});

  final List<Bid> offers;
  final Map<String, Job> jobs;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (offers.isEmpty) {
      return EmptyView(
        icon: Icons.local_offer_outlined,
        title: strings.noOffers,
        message: strings.noOffersMessage,
      );
    }

    final now = DateTime.now();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceXl * 3,
      ),
      itemCount: offers.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: BrandSizing.spaceSm + 4),
      itemBuilder: (context, index) {
        final offer = offers[index];
        final job = jobs[offer.jobId]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JobRow(
              job: job,
              now: now,
              onTap: () => JobDetailsSheet.open(
                context,
                jobId: job.id,
                mediaStore: context.read<MediaStore>(),
              ),
            ),
            const SizedBox(height: BrandSizing.spaceXs),
            _OfferOutcome(offer: offer, strings: strings),
          ],
        );
      },
    );
  }
}

class _OfferOutcome extends StatelessWidget {
  const _OfferOutcome({required this.offer, required this.strings});

  final Bid offer;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (label, colour) = switch (offer.status) {
      BidStatus.accepted => (strings.chosen, BrandColours.successTeal),
      BidStatus.passedOver => (
        strings.offerNotChosen,
        theme.colorScheme.onSurfaceVariant,
      ),
      BidStatus.withdrawn => (
        strings.offerWithdrawn,
        theme.colorScheme.onSurfaceVariant,
      ),
      BidStatus.offered => (strings.offerWaiting, theme.colorScheme.primary),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BrandSizing.spaceSm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              strings.yourOffer(Format.fare(strings, offer.fare)),
              style: theme.textTheme.labelMedium,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colour,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobsTab extends StatelessWidget {
  const _JobsTab({
    required this.jobs,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.notice,
  });

  final List<Job> jobs;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return EmptyView(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    final now = DateTime.now();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceXl * 3,
      ),
      itemCount: jobs.length + (notice == null ? 0 : 1),
      separatorBuilder: (_, _) =>
          const SizedBox(height: BrandSizing.spaceSm + 4),
      itemBuilder: (context, index) {
        if (notice != null && index == 0) {
          return NoticePanel(message: notice!);
        }

        final job = jobs[index - (notice == null ? 0 : 1)];
        return JobRow(
          job: job,
          now: now,
          onTap: () => JobDetailsSheet.open(
            context,
            jobId: job.id,
            mediaStore: context.read<MediaStore>(),
          ),
        );
      },
    );
  }
}
