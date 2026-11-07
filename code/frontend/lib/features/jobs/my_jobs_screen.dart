import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/account_controller.dart';
import '../../app/bid_controller.dart';
import '../../app/job_controller.dart';
import '../../app/profile_controller.dart';
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
import '../../widgets/counted_label.dart';
import '../../widgets/job_skeleton.dart';
import '../../widgets/state_views.dart';
import 'job_details_sheet.dart';
import 'job_row.dart';
import 'saved_jobs_controller.dart';
import '../account/account_switcher.dart';

/// Activity: what arrived, and what you are keeping an eye on.
///
/// **Three tabs since 0.23, not five.** Updates and Messages arrive while you
/// are away; *Your jobs* is three lists you go and check — what you posted,
/// what you offered on, what you saved. As five scrolling tabs, Offers sat off
/// the right edge of a phone with nothing to say it was there, and Offers is
/// where a worker learns whether they were chosen.
///
/// The three lists are subsets of one list of jobs, so inside *Your jobs* they
/// are a segmented control rather than three more tabs.
class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final jobs = context.watch<JobController>();
    final compact = LayoutSize.of(context) == LayoutSize.compact;

    final unseen = context.watch<NotificationController>().unseen(
      buildFeed(context),
    );
    final waiting = context.watch<MessageController>().threadsWaiting(
      jobs.jobs,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.navActivity),
        actions: const [AccountButton()],
        bottom: TabBar(
          controller: _tabs,
          // **On a phone, three equal tabs across the whole width**, so none
          // can sit past the edge — which is where Offers was when there were
          // five. On a wider window, three tabs stretched across 1,200px read
          // as three buttons, so there they sit together under the title.
          isScrollable: !compact,
          tabAlignment: compact ? TabAlignment.fill : TabAlignment.start,
          tabs: [
            // Updates first: it is the reason to open this destination at all,
            // and the badge on the navigation bar lands here.
            Tab(
              text: unseen == 0
                  ? strings.updatesTab
                  : '${strings.updatesTab} · $unseen',
            ),
            Tab(
              text: waiting == 0
                  ? strings.messagesTab
                  : '${strings.messagesTab} · $waiting',
            ),
            Tab(text: strings.yourJobsTab),
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
            children: const [UpdatesTab(), ThreadsTab(), _YourJobs()],
          ),
        },
      ),
    );
  }
}

/// Which of your lists is showing.
enum _Mine { posted, offers, saved }

/// The jobs that are yours one way or another, filtered three ways.
class _YourJobs extends StatefulWidget {
  const _YourJobs();

  @override
  State<_YourJobs> createState() => _YourJobsState();
}

class _YourJobsState extends State<_YourJobs> {
  /// Null until somebody picks one; until then it follows the role, because a
  /// hirer comes here for their postings and a worker for their offers.
  _Mine? _picked;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final jobs = context.watch<JobController>();
    final saved = context.watch<SavedJobsController>();
    final isWorker = context.watch<ProfileController>().isWorker;

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

    final showing = _picked ?? (isWorker ? _Mine.offers : _Mine.posted);

    ButtonSegment<_Mine> segment(_Mine value, String label, int count) =>
        ButtonSegment(
          value: value,
          label: CountedLabel(label: label, count: count),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BrandSizing.spaceMd,
            BrandSizing.spaceMd,
            BrandSizing.spaceMd,
            BrandSizing.spaceSm,
          ),
          child: SegmentedButton<_Mine>(
            showSelectedIcon: false,
            segments: [
              segment(_Mine.posted, strings.postedTab, myPostings.length),
              segment(_Mine.offers, strings.offersTab, myOffers.length),
              segment(_Mine.saved, strings.savedTab, savedJobs.length),
            ],
            selected: {showing},
            onSelectionChanged: (value) =>
                setState(() => _picked = value.single),
          ),
        ),
        Expanded(
          child: switch (showing) {
            _Mine.posted => _JobsTab(
              jobs: myPostings,
              emptyIcon: Icons.work_outline,
              emptyTitle: strings.noPostings,
              emptyMessage: strings.noPostingsMessage,
              marksOwnPostings: false,
            ),
            _Mine.offers => _OffersTab(offers: myOffers, jobs: byId),
            _Mine.saved => _JobsTab(
              jobs: savedJobs,
              emptyIcon: Icons.bookmark_border,
              emptyTitle: strings.noSavedJobs,
              emptyMessage: strings.noSavedJobsMessage,
              // Said once, rather than letting the list quietly shrink.
              notice: saved.hasMissing(jobs.jobs) ? strings.savedJobGone : null,
            ),
          },
        ),
      ],
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
      padding: const EdgeInsets.only(bottom: BrandSizing.spaceXl),
      itemCount: offers.length,
      separatorBuilder: (_, _) => const Divider(indent: BrandSizing.spaceMd),
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
            _OfferOutcome(offer: offer, strings: strings),
            const SizedBox(height: BrandSizing.spaceSm + 4),
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
      padding: const EdgeInsets.symmetric(horizontal: BrandSizing.spaceMd),
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
    this.marksOwnPostings = true,
  });

  final List<Job> jobs;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String? notice;

  /// See [JobRow.marksOwnPosting].
  final bool marksOwnPostings;

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
      padding: const EdgeInsets.only(bottom: BrandSizing.spaceXl),
      itemCount: jobs.length + (notice == null ? 0 : 1),
      separatorBuilder: (_, index) => notice != null && index == 0
          ? const SizedBox(height: BrandSizing.spaceSm)
          : const Divider(indent: BrandSizing.spaceMd),
      itemBuilder: (context, index) {
        if (notice != null && index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BrandSizing.spaceMd,
            ),
            child: NoticePanel(message: notice!),
          );
        }

        final job = jobs[index - (notice == null ? 0 : 1)];
        return JobRow(
          job: job,
          marksOwnPosting: marksOwnPostings,
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
