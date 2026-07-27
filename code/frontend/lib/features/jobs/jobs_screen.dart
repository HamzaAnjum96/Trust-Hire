import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/job_controller.dart';
import '../../core/formatters.dart';
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

    final visible = filters.apply(
      controller.jobs,
      strings: strings,
      from: location.position,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.findWork),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
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
      body: switch (controller.state) {
        // A placeholder in the shape of the content beats a spinner: it
        // says what is coming and stops the layout jumping.
        LoadState.idle || LoadState.loading => const JobListSkeleton(),
        LoadState.failed => ErrorView(
          message: controller.errorMessage ?? strings.couldNotLoadJobsShort,
          onRetry: controller.load,
        ),
        LoadState.ready => _Results(
          all: controller.jobs,
          visible: visible,
          filters: filters,
        ),
      },
    );
  }
}

/// Results, or an empty state that distinguishes "nothing posted" from
/// "nothing matches" — they need different next steps.
class _Results extends StatelessWidget {
  const _Results({
    required this.all,
    required this.visible,
    required this.filters,
  });

  final List<Job> all;
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
        child: _JobRow(job: jobs[index], now: now),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.now});

  final Job job;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => JobDetailsSheet.open(
          context,
          jobId: job.id,
          mediaStore: context.read<MediaStore>(),
        ),
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
                      job.displayTitle(strings),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (job.isLocal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BrandSizing.spaceSm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColours.copper,
                        borderRadius: BrandRadius.smallAll,
                      ),
                      child: Text(
                        strings.onThisDevice,
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: BrandColours.white,
                        ),
                      ),
                    ),
                ],
              ),
              if (job.supportingDescription != null) ...[
                const SizedBox(height: BrandSizing.spaceXs),
                Text(
                  job.supportingDescription!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: BrandSizing.spaceSm + 4),
              Wrap(
                spacing: BrandSizing.spaceMd,
                runSpacing: BrandSizing.spaceXs,
                children: [
                  if (job.type != null)
                    _Meta(
                      icon: job.type!.icon,
                      label: job.type!.label(strings),
                    ),
                  _Meta(
                    icon: Icons.schedule,
                    label: Format.scheduled(strings, job.scheduledTime, now),
                  ),
                  if (job.hasVoiceNote)
                    _Meta(icon: Icons.mic, label: strings.voiceNote),
                  if (job.hasPhotos)
                    _Meta(
                      icon: Icons.photo_library_outlined,
                      label: strings.photoCount(job.photoPaths.length),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: BrandSizing.spaceXs + 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
