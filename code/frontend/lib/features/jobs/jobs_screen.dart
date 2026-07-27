import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../app/profile_controller.dart';
import '../../core/layout.dart';
import '../../core/motion.dart';
import '../../core/tokens.dart';
import '../../models/job.dart';
import '../map/location_controller.dart';
import '../../services/media_store.dart';
import '../../widgets/job_skeleton.dart';
import '../../widgets/state_views.dart';
import 'filter_bar.dart';
import 'job_details_sheet.dart';
import 'job_filter_controller.dart';
import 'job_row.dart';
import '../profile/my_trades_screen.dart';
import '../../l10n/app_localizations.dart';

/// A plain list of every job in local storage.
///
/// The map is the product, so this is a secondary view — but it proves the
/// data pipeline end to end and gives a keyboard-free way to reach a job.
class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final controller = context.watch<JobController>();
    final filters = context.watch<JobFilterController>();
    final location = context.watch<LocationController>();
    final profile = context.watch<ProfileController>();

    // Two passes, in this order: the tag and geofence rule the user does not
    // control, then the filters they do. Collapsing them would make "clear
    // filters" look like it should bring back a job it cannot.
    final reachable = profile.visibleTo(
      controller.jobs,
      from: location.position,
    );
    final visible = filters.apply(
      reachable,
      strings: strings,
      from: location.position,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.findWork),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: ReadableWidth(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BrandSizing.spaceMd,
                    0,
                    BrandSizing.spaceMd,
                    BrandSizing.spaceSm,
                  ),
                  child: JobSearchField(controller: filters),
                ),
                QuickFilterBar(controller: filters),
                const SizedBox(height: BrandSizing.spaceSm),
              ],
            ),
          ),
        ),
      ),
      // A job row across a 1440px browser is a band of white holding forty
      // characters. Everything on this screen shares one measure so the
      // search field, the filters and the rows line up.
      body: ReadableWidth(
        child: switch (controller.state) {
          // A placeholder in the shape of the content beats a spinner: it
          // says what is coming and stops the layout jumping.
          LoadState.idle || LoadState.loading => const JobListSkeleton(),
          LoadState.failed => ErrorView(
            message: strings.couldNotLoadJobs,
            onRetry: controller.load,
          ),
          LoadState.ready => _Results(
            all: controller.jobs,
            reachable: reachable,
            visible: visible,
            filters: filters,
          ),
        },
      ),
    );
  }
}

/// Results, or an empty state that distinguishes "nothing posted" from
/// "nothing matches" — they need different next steps.
class _Results extends StatelessWidget {
  const _Results({
    required this.all,
    required this.reachable,
    required this.visible,
    required this.filters,
  });

  final List<Job> all;

  /// Everything the visibility rule allows, before the user's own filters.
  final List<Job> reachable;

  final List<Job> visible;
  final JobFilterController filters;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (all.isEmpty) {
      return EmptyView(
        icon: Icons.work_outline,
        title: strings.noJobsYet,
        message: strings.postTheFirstJob,
      );
    }

    // Three empty states, because they need three different next steps.
    // Clearing filters cannot bring back a job the tag rule excluded, so
    // offering that button here would be a dead end.
    if (reachable.isEmpty) {
      return EmptyView(
        icon: Icons.construction_outlined,
        title: strings.noJobsForTrades,
        message: strings.noJobsForTradesHelp,
        action: OutlinedButton(
          onPressed: () => MyTradesScreen.open(context),
          child: Text(strings.addATrade),
        ),
      );
    }

    if (visible.isEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: strings.noJobsMatch,
        message: strings.tryWiderArea,
        action: OutlinedButton(
          onPressed: filters.clear,
          child: Text(strings.clearFilters),
        ),
      );
    }

    return _JobList(jobs: visible);
  }
}

class _JobList extends StatelessWidget {
  const _JobList({required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        BrandSizing.spaceMd,
        // Clear the floating action button.
        BrandSizing.spaceXl * 3,
      ),
      itemCount: jobs.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: BrandSizing.spaceSm + 4),
      itemBuilder: (context, index) => SettleIn(
        // A short stagger so the list assembles rather than snapping in.
        delay: Duration(milliseconds: (index * 40).clamp(0, 240)),
        child: JobRow(
          job: jobs[index],
          now: now,
          onTap: () => JobDetailsSheet.open(
            context,
            jobId: jobs[index].id,
            mediaStore: context.read<MediaStore>(),
          ),
        ),
      ),
    );
  }
}
