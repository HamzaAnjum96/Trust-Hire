import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../services/media_store.dart';
import '../../widgets/job_skeleton.dart';
import '../../widgets/state_views.dart';
import 'job_details_sheet.dart';
import 'job_row.dart';
import 'saved_jobs_controller.dart';

/// The two lists that are about *you* — work you kept, and work you offered.
///
/// Both are answers to the same gap: the app had nowhere to come back to. A
/// worker who found a job had to find it again; a poster had no home for what
/// they had posted.
class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

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
    final myPostings = jobs.jobs.where((job) => job.isLocal).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.navSaved),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: '${strings.savedTab} · ${savedJobs.length}'),
            Tab(text: '${strings.postedTab} · ${myPostings.length}'),
          ],
        ),
      ),
      body: switch (jobs.state) {
        LoadState.idle || LoadState.loading => const JobListSkeleton(),
        LoadState.failed => ErrorView(
          message: jobs.errorMessage ?? strings.couldNotLoadJobsShort,
          onRetry: jobs.load,
        ),
        LoadState.ready => TabBarView(
          controller: _tabs,
          children: [
            _JobsTab(
              jobs: savedJobs,
              emptyIcon: Icons.bookmark_border,
              emptyTitle: strings.noSavedJobs,
              emptyMessage: strings.noSavedJobsMessage,
              // Said once, rather than letting the list quietly shrink.
              notice: saved.hasMissing(jobs.jobs) ? strings.savedJobGone : null,
            ),
            _JobsTab(
              jobs: myPostings,
              emptyIcon: Icons.work_outline,
              emptyTitle: strings.noPostings,
              emptyMessage: strings.noPostingsMessage,
            ),
          ],
        ),
      },
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
