import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../core/layout.dart';
import '../../core/roles.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/job_skeleton.dart';
import '../../widgets/state_views.dart';
import '../map/map_screen.dart';
import 'my_jobs_screen.dart';

/// The Jobs destination: work near you, and your own jobs, on two tabs.
///
/// **Your jobs moved here in 0.26.** They sat in Activity beside the
/// notification feed and the messages, so the jobs you posted or offered on
/// were under a destination named for news. A job is a job: the ones near you
/// and the ones that are yours now share a destination, and Activity became
/// the Inbox.
///
/// The two views are stacked rather than paged: swiping the map must never
/// flip the tab, and the map keeps its place when you come back to it.
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(_onTab);

  void _onTab() {
    if (!_tabs.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTab)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final compact = LayoutSize.of(context) == LayoutSize.compact;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: context.colours.page,
              child: TabBar(
                controller: _tabs,
                // Two equal tabs across a phone; on a wider window they sit
                // together at the start rather than stretching 1,200px apart.
                isScrollable: !compact,
                tabAlignment: compact ? TabAlignment.fill : TabAlignment.start,
                tabs: [
                  Tab(text: strings.jobsNearYouTab),
                  Tab(text: strings.yourJobsTab),
                ],
              ),
            ),
            Expanded(
              // The tab bar already took the status bar's room.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: IndexedStack(
                  index: _tabs.index,
                  children: const [MapScreen(), _YourJobsPage()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Your jobs, once the jobs have loaded.
class _YourJobsPage extends StatelessWidget {
  const _YourJobsPage();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final jobs = context.watch<JobController>();

    return ReadableWidth(
      child: switch (jobs.state) {
        LoadState.idle || LoadState.loading => const JobListSkeleton(),
        LoadState.failed => ErrorView(
          message: strings.couldNotLoadJobs,
          onRetry: jobs.load,
        ),
        LoadState.ready => const YourJobsView(),
      },
    );
  }
}
